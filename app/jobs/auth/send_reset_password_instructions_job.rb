# frozen_string_literal: true

module Auth
  class SendResetPasswordInstructionsJob < ApplicationJob
    def perform(email)
      User.for_email(email)&.send_reset_password_instructions
    end
  end
end
