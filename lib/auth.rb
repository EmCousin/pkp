# frozen_string_literal: true

require 'openssl'
require 'uri/mailto'

module Auth
  class << self
    attr_accessor :email_regexp,
                  :inactivity_timeout,
                  :last_seen_touch_interval,
                  :mailer_sender,
                  :maximum_attempts,
                  :password_length,
                  :recovery_delivery_cooldown,
                  :recovery_request_limit,
                  :recovery_request_period,
                  :remember_for,
                  :reset_password_within,
                  :unlock_in

    def configure
      yield self
    end

    def token_digest(column, token)
      return if token.blank?

      OpenSSL::HMAC.hexdigest('SHA256', token_key_generator.generate_key("Devise #{column}"), token.to_s)
    end

    private

    def token_key_generator
      @token_key_generator ||= ActiveSupport::CachingKeyGenerator.new(
        ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
      )
    end
  end

  self.email_regexp = URI::MailTo::EMAIL_REGEXP
  self.inactivity_timeout = 30.minutes
  self.last_seen_touch_interval = 1.minute
  self.mailer_sender = 'noreply@example.com'
  self.maximum_attempts = 5
  self.password_length = 6..72
  self.recovery_delivery_cooldown = 1.minute
  self.recovery_request_limit = 10
  self.recovery_request_period = 3.minutes
  self.remember_for = 2.weeks
  self.reset_password_within = 6.hours
  self.unlock_in = 1.hour
end
