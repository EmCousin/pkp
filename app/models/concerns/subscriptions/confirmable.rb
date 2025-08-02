# frozen_string_literal: true

module Subscriptions
  module Confirmable
    extend ActiveSupport::Concern

    def confirm!
      confirmed!
      notify_confirmation!
    end

    def notify_confirmation!
      if courses.any?
        SubscriptionMailer.confirm_subscription(self).deliver_later
      else
        SubscriptionMailer.confirm_camp_subscription(self).deliver_later
      end
    end
  end
end
