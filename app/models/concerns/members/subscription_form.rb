# frozen_string_literal: true

module Members
  module SubscriptionForm
    extend ActiveSupport::Concern

    RELEVANT_ATTRIBUTES = %w[
      first_name
      last_name
      birthdate
      contact_name
      contact_phone_number
      contact_relationship
    ].freeze

    included do
      after_update :clear_subscription_forms, if: :relevant_attributes_changed?
    end

    private

    def clear_subscription_forms
      subscriptions.with_attached_form.find_each do |subscription|
        subscription.form.purge if subscription.form.attached?
      end
    end

    def relevant_attributes_changed?
      RELEVANT_ATTRIBUTES.any? { |attr| send("saved_change_to_#{attr}?") }
    end
  end
end
