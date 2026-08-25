# frozen_string_literal: true

module Auth
  module Recoverable
    extend ActiveSupport::Concern

    class_methods do
      def from_reset_password_token(token)
        return if token.blank?

        where(reset_password_sent_at: User::RESET_PASSWORD_WITHIN.ago..)
          .find_by(reset_password_token: token_digest(token))
      end

      def token_digest(token)
        Digest::SHA256.hexdigest(token)
      end
    end

    def send_reset_password_instructions
      token = SecureRandom.urlsafe_base64(32)
      update_columns( # rubocop:disable Rails/SkipsModelValidations
        reset_password_token: self.class.token_digest(token),
        reset_password_sent_at: Time.current
      )
      Auth::Mailer.reset_password_instructions(self, token).deliver_now
      token
    end

    def reset_password(token:, password:, password_confirmation:)
      with_lock do
        next false unless valid_reset_password_change?(token, password, password_confirmation)

        assign_attributes(reset_password_attributes(password, password_confirmation))
        save
      end
    end

    private

    def valid_reset_password_token?(token)
      reset_password_token.present? &&
        reset_password_sent_at&.after?(User::RESET_PASSWORD_WITHIN.ago) &&
        ActiveSupport::SecurityUtils.secure_compare(reset_password_token, self.class.token_digest(token.to_s))
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
