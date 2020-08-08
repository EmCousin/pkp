# frozen_string_literal: true

module Users
  module AdminNotifiable
    extend ActiveSupport::Concern

    included do
      before_update :notify_admins, if: :email_changed?
    end

    private

    def notify_admins
      AdminMailer.email_changed(email_was, email).deliver_later
    end
  end
end
