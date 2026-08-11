# frozen_string_literal: true

class CampRegistration < EventRegistration
  validates :subscription_camp, presence: true
  validates :courses, :discovery_session, absence: true

  def self.model_name
    Subscription.model_name
  end

  def completion_open?
    !camp.starts_at.past?
  end

  def description
    @description ||= camp.title
  end

  def invoice_label
    I18n.t('billing.invoice.camp_label', description:)
  end

  def invoice_details
    dates = I18n.t(
      'billing.invoice.camp_dates',
      starts_at: I18n.l(camp.starts_at, format: :long),
      ends_at: I18n.l(camp.ends_at, format: :long)
    )
    rate = I18n.t("billing.invoice.#{parent_subscription_id? ? 'internal_rate' : 'external_rate'}")
    [dates, rate]
  end

  def notify_confirmation!
    SubscriptionMailer.confirm_camp_subscription(self).deliver_later
  end

  private

  def calculated_fee
    subscription_camp&.price_for(member)
  end

  def registration_event
    subscription_camp
  end
end
