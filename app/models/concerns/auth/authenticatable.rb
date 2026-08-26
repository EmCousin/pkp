# frozen_string_literal: true

module Auth
  module Authenticatable
    extend ActiveSupport::Concern
    include Auth::Recoverable
    include Auth::Lockable

    included do
      alias_attribute :password_digest, :encrypted_password
      has_secure_password

      has_many :auth_sessions,
               class_name: 'Auth::Session',
               dependent: :destroy

      attr_accessor :current_password

      validates :email, presence: true, format: { with: Auth.email_regexp }, uniqueness: true
      validates :password,
                length: { in: Auth.password_length },
                if: :password

      normalizes :email, with: ->(email) { email.strip.downcase }

      before_update :invalidate_reset_password_token, if: :authentication_credentials_changing?
      before_update :invalidate_auth_sessions, if: :will_save_change_to_encrypted_password?
      after_update_commit :notify_password_changed, if: :saved_change_to_encrypted_password?
      after_update_commit :notify_email_changed, if: :saved_change_to_email?
    end

    class_methods do
      def authenticate_for_session(email:, password:)
        normalized_email = normalize_value_for(:email, email.to_s)
        user = find_by(email: normalized_email)
        authenticated_user = authenticate_by(email: normalized_email, password: password.to_s)

        user&.unlock_if_expired!
        return if user&.access_locked?

        authenticated_user ? authenticated_user.reset_failed_authentications! : user&.register_failed_authentication!
        authenticated_user
      end

      def for_email(email)
        find_by(email: normalize_value_for(:email, email.to_s))
      end
    end

    def valid_password?(password)
      authenticate(password).present?
    end

    def authentication_fingerprint
      Digest::SHA256.hexdigest(encrypted_password)
    end

    def update_account(attributes, current_password:)
      with_lock do
        self.current_password = current_password
        errors.add(:current_password, :invalid) unless authenticate(current_password)
        next false if errors.any?

        assign_attributes(attributes)
        save(context: :account_setup)
      end
    end

    private

    def notify_email_changed
      previous_email, = saved_change_to_email
      enqueue_security_notification Auth::Mailer.email_changed(previous_email, email)
    end

    def notify_password_changed
      enqueue_security_notification Auth::Mailer.password_changed(email)
    end

    def authentication_credentials_changing?
      will_save_change_to_email? || will_save_change_to_encrypted_password?
    end

    def invalidate_reset_password_token
      self.reset_password_token = nil
      self.reset_password_sent_at = nil
    end

    def invalidate_auth_sessions
      advance_authentication_generation
      auth_sessions.delete_all
    end

    def advance_authentication_generation
      self.authentication_generation = SecureRandom.random_number(1...(2**63))
    end

    def enqueue_security_notification(message)
      message.deliver_later
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { user_id: id })
    end
  end
end
