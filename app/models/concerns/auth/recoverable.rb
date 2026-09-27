# frozen_string_literal: true

module Auth
  module Recoverable
    extend ActiveSupport::Concern

    class_methods do
      def from_reset_password_token(token)
        return if token.blank?

        find_by_token_for(:password_reset, token)
      end
    end

    def send_reset_password_instructions
      token = generate_token_for(:password_reset)
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
      self.class.find_by_token_for(:password_reset, token) == self
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
        failed_attempts: 0,
        locked_at: nil
      }
    end
  end
end
