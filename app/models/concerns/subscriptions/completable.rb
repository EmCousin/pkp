# frozen_string_literal: true

module Subscriptions
  module Completable
    extend ActiveSupport::Concern

    included do
      attribute :terms_accepted, :boolean, default: false
      attribute :doctor_certified, :boolean, default: false

      has_one_attached :form
      has_one_attached :medical_certificate

      scope :with_direct_medical_certificate, lambda {
        where.not(doctor_certified_at: nil).joins(:medical_certificate_attachment)
      }
    end

    def completed?
      return paid? && terms_accepted_at? unless medical_certificate_required?

      paid? && terms_accepted_at? && medical_certificate_valid?
    end

    def medical_certificate_valid?
      medical_certificate_source.present?
    end

    def medical_certificate_source
      return @medical_certificate_source if defined?(@medical_certificate_source)

      @medical_certificate_source = if own_medical_certificate_valid?
                                      self
                                    else
                                      previous_medical_certificate_source
                                    end
    end

    def effective_medical_certificate
      medical_certificate_source&.medical_certificate
    end

    def inherited_medical_certificate?
      source = medical_certificate_source
      source.present? && source != self
    end

    def medical_certificate_source_in_use?
      return false if destroyed_by_association
      return false unless own_medical_certificate_valid? && member&.platform

      medical_certificate_dependents.any? { |subscription| subscription.medical_certificate_source == self }
    end

    def pending_confirmation?
      pending? && completed?
    end

    def terms_accepted=(value)
      accepted = super
      self.terms_accepted_at = accepted ? Time.current : nil
    end

    def doctor_certified=(value)
      remove_instance_variable(:@medical_certificate_source) if defined?(@medical_certificate_source)
      certified = super
      self.doctor_certified_at = certified ? Time.current : nil
    end

    private

    def own_medical_certificate_valid?
      doctor_certified_at? && medical_certificate.attached?
    end

    def previous_medical_certificate_source
      return unless medical_certificate_history_available?
      return loaded_medical_certificate_source if member.subscriptions.loaded?

      member.subscriptions
            .with_direct_medical_certificate
            .where(type: AnnualSubscription.sti_name, parent_subscription_id: nil, year: medical_certificate_validity_years)
            .includes(medical_certificate_attachment: :blob)
            .order(year: :desc, id: :desc)
            .first
    end

    def medical_certificate_history_available?
      medical_certificate_required? && persisted? && member&.platform
    end

    def loaded_medical_certificate_source
      member.subscriptions
            .select { |source| medical_certificate_source_candidate?(source) }
            .max_by { |source| [source.year, source.id] }
    end

    def medical_certificate_source_candidate?(source)
      source.is_a?(AnnualSubscription) &&
        source.parent_subscription_id.nil? &&
        medical_certificate_validity_years.cover?(source.year) &&
        source.doctor_certified_at? &&
        source.medical_certificate.attached?
    end

    def medical_certificate_validity_years
      validity_seasons = member.platform.medical_certificate_validity_seasons
      (year - validity_seasons + 1)..year
    end

    def medical_certificate_dependents
      last_valid_year = year + member.platform.medical_certificate_validity_seasons - 1
      member.subscriptions.where(
        type: AnnualSubscription.sti_name,
        parent_subscription_id: nil,
        year: (year + 1)..last_valid_year
      )
    end
  end
end
