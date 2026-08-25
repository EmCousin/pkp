# frozen_string_literal: true

module Auth
  module Lockable
    extend ActiveSupport::Concern

    class_methods do
      def unlock_by_token(token)
        return if token.blank?

        find_by(unlock_token: token_digest(token))&.tap(&:unlock_access!)
      end
    end

    def access_locked?
      locked_at? && !lock_expired?
    end

    def lock_expired?
      locked_at? && locked_at <= User::LOCK_DURATION.ago
    end

    def unlock_if_expired!
      unlock_access! if lock_expired?
    end

    def unlock_access!
      update_columns( # rubocop:disable Rails/SkipsModelValidations
        failed_attempts: 0,
        locked_at: nil,
        unlock_token: nil,
        updated_at: Time.current
      )
      self
    end

    def send_unlock_instructions
      unlock_if_expired!
      return unless access_locked?

      token = SecureRandom.urlsafe_base64(32)
      update_columns(unlock_token: self.class.token_digest(token), updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      Auth::Mailer.unlock_instructions(self, token).deliver_now
      token
    end

    def register_failed_authentication!
      newly_locked = with_lock do
        locked = record_failed_authentication
        auth_sessions.delete_all if locked
        locked
      end
      return unless newly_locked

      Auth::SendUnlockInstructionsJob.perform_later(email)
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { user_id: id })
    end

    def reset_failed_authentications!
      return if failed_attempts.zero? && !locked_at? && unlock_token.blank?

      update_columns( # rubocop:disable Rails/SkipsModelValidations
        failed_attempts: 0,
        locked_at: nil,
        unlock_token: nil,
        updated_at: Time.current
      )
    end

    private

    def record_failed_authentication
      return if access_locked?

      self.failed_attempts += 1
      newly_locked = failed_attempts >= User::MAXIMUM_AUTHENTICATION_ATTEMPTS
      lock_access if newly_locked
      save!(validate: false)
      newly_locked
    end

    def lock_access
      self.locked_at = Time.current
      self.unlock_token = nil
      advance_authentication_generation
    end
  end
end
