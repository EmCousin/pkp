# frozen_string_literal: true

module Auth
  class SendUnlockInstructionsJob < ApplicationJob
    def perform(email)
      User.for_email(email)&.send_unlock_instructions
    end
  end
end
