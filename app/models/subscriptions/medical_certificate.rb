# frozen_string_literal: true

module Subscriptions
  class MedicalCertificate
    include ActiveModel::Model

    attr_reader :subscription

    validates :source, presence: { message: :required }

    def initialize(subscription:)
      @subscription = subscription
    end

    def source
      return @source if defined?(@source)

      @source = own_certificate_valid? ? subscription : previous_source
    end

    def attachment
      source&.medical_certificate
    end

    def inherited?
      source.present? && source != subscription
    end

    def source_in_use?
      return false if subscription.destroyed_by_association
      return false unless own_certificate_valid? && subscription.member&.platform

      dependents.any? do |dependent|
        self.class.new(subscription: dependent).source == subscription
      end
    end

    private

    def own_certificate_valid?
      subscription.doctor_certified_at? && subscription.medical_certificate.attached?
    end

    # rubocop:disable Metrics/AbcSize
    def previous_source
      return unless history_available?
      return loaded_source if subscription.member.subscriptions.loaded?

      subscription.member.subscriptions
                  .where.not(doctor_certified_at: nil)
                  .joins(:medical_certificate_attachment)
                  .where(type: AnnualSubscription.sti_name, parent_subscription_id: nil, year: validity_years)
                  .includes(medical_certificate_attachment: :blob)
                  .order(year: :desc, id: :desc)
                  .first
    end
    # rubocop:enable Metrics/AbcSize

    def history_available?
      subscription.medical_certificate_required? && subscription.persisted? && subscription.member&.platform
    end

    def loaded_source
      subscription.member.subscriptions
                  .select { |candidate| source_candidate?(candidate) }
                  .max_by { |candidate| [candidate.year, candidate.id] }
    end

    def source_candidate?(candidate)
      candidate.is_a?(AnnualSubscription) &&
        candidate.parent_subscription_id.nil? &&
        validity_years.cover?(candidate.year) &&
        candidate.doctor_certified_at? &&
        candidate.medical_certificate.attached?
    end

    def validity_years
      validity_seasons = subscription.member.platform.medical_certificate_validity_seasons
      (subscription.year - validity_seasons + 1)..subscription.year
    end

    def dependents
      last_valid_year = subscription.year + subscription.member.platform.medical_certificate_validity_seasons - 1
      subscription.member.subscriptions.where(
        type: AnnualSubscription.sti_name,
        parent_subscription_id: nil,
        year: (subscription.year + 1)..last_valid_year
      )
    end
  end
end
