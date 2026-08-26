# frozen_string_literal: true

module Auth
  module Authenticatable
    extend ActiveSupport::Concern
    include Auth::Recoverable
    include Auth::Lockable

    included do
      alias_attribute :password_digest, :encrypted_password
      has_secure_password validations: false, reset_token: false

      generates_token_for :password_reset, expires_in: Auth.reset_password_within do
        [password_salt&.last(10), Digest::SHA256.hexdigest(email)]
      end
      generates_token_for :unlock, expires_in: Auth.unlock_in do
        [locked_at&.to_i, authentication_generation]
      end

      has_many :auth_sessions,
               class_name: 'Auth::Session',
               dependent: :destroy

      attr_accessor :current_password

      validates :email, presence: true, format: { with: Auth.email_regexp }, uniqueness: true
      validate :password_digest_present
      validates :password,
                confirmation: true,
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

    def password_digest_present
      errors.add(:password, :blank) if password_digest.blank?
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
