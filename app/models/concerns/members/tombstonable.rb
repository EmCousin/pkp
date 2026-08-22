# frozen_string_literal: true

module Members
  module Tombstonable
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(tombstoned_at: nil) }

      validates :user, presence: true, unless: :tombstoned_at?
    end

    def deactivate!
      transaction do
        destroyable? ? destroy! : tombstone!
      end
    end

    private

    def tombstone!
      destroy_unprotected_subscriptions
      attendance_records.destroy_all
      avatar.purge_later
      purge_personal_subscription_files

      update_columns(tombstone_attributes) # rubocop:disable Rails/SkipsModelValidations
    end

    def destroy_unprotected_subscriptions
      subscriptions.to_a
                   .sort_by { |subscription| subscription.parent_subscription_id? ? 0 : 1 }
                   .each { |subscription| subscription.destroy if subscription.cancellable? }
    end

    def tombstone_attributes
      {
        user_id: nil, first_name: nil, last_name: nil, birthdate: nil,
        contact_name: nil, contact_phone_number: nil, contact_relationship: nil,
        agreed_to_advertising_right: false, tombstoned_at: Time.current, updated_at: Time.current
      }
    end

    def purge_personal_subscription_files
      subscriptions.find_each do |subscription|
        subscription.form.purge_later
        subscription.medical_certificate.purge_later
      end
    end
  end
end
