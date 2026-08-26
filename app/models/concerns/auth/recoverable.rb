# frozen_string_literal: true

module Auth
  module Recoverable
    extend ActiveSupport::Concern

    class_methods do
      def from_reset_password_token(token)
        return if token.blank?

        find_by(
          reset_password_sent_at: Auth.reset_password_within.ago..,
          reset_password_token: Auth.token_digest(:reset_password_token, token)
        )
      end
    end

    def send_reset_password_instructions
      token, digest = issue_reset_password_token
      return unless token

      Auth::Mailer.reset_password_instructions(self, token).deliver_now
      token
    rescue StandardError
      clear_undelivered_reset_password_token(digest)
      raise
    end

    def reset_password(token:, password:, password_confirmation:)
      with_lock do
        next false unless valid_reset_password_change?(token, password, password_confirmation)

        assign_attributes(reset_password_attributes(password, password_confirmation))
        save
      end
    end

    private

    def issue_reset_password_token
      with_lock do
        next if reset_password_sent_at&.after?(Auth.recovery_delivery_cooldown.ago)

        token = SecureRandom.urlsafe_base64(32)
        digest = Auth.token_digest(:reset_password_token, token)
        update_columns( # rubocop:disable Rails/SkipsModelValidations
          reset_password_token: digest,
          reset_password_sent_at: Time.current
        )
        [token, digest]
      end
    end

    def clear_undelivered_reset_password_token(digest)
      return unless digest

      self.class.where(id:, reset_password_token: digest).update_all( # rubocop:disable Rails/SkipsModelValidations
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
    end

    def valid_reset_password_token?(token)
      reset_password_token.present? &&
        reset_password_sent_at&.after?(Auth.reset_password_within.ago) &&
        ActiveSupport::SecurityUtils.secure_compare(
          reset_password_token,
          Auth.token_digest(:reset_password_token, token.to_s)
        )
    end

    def valid_reset_password_change?(token, password, password_confirmation)
      errors.add(:reset_password_token, :invalid) unless valid_reset_password_token?(token)
      errors.add(:password, :blank) if password.blank?
      errors.add(:password_confirmation, :blank) if password_confirmation.blank?
      errors.empty?
    end

    def reset_password_attributes(password, password_confirmation)
      {
        password:,
        password_confirmation:,
        reset_password_token: nil,
        reset_password_sent_at: nil,
        failed_attempts: 0,
        locked_at: nil,
        unlock_token: nil
      }
    end
  end
end
