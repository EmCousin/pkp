# frozen_string_literal: true

module Users
  module AdminNotifiable
    extend ActiveSupport::Concern

    included do
      after_update_commit :notify_admins, if: :saved_change_to_email?
    end

    private

    def notify_admins
      previous_email, current_email = saved_change_to_email
      AdminMailer.email_changed(previous_email, current_email).deliver_later
    rescue StandardError => e
      Rails.error.report(e, handled: true, context: { user_id: id })
    end
  end
end
