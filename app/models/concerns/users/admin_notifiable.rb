# frozen_string_literal: true

module Users
  module AdminNotifiable
    extend ActiveSupport::Concern

    included do
      before_update :notify_admins, if: :will_save_change_to_email?
    end

    private

    def notify_admins
      AdminMailer.email_changed(email_was, email).deliver_later
    end
  end
end
