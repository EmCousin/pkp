# frozen_string_literal: true

class CoursesSubscription < ApplicationRecord
  belongs_to :course
  belongs_to :subscription

  delegate :billing_invoice, to: :subscription, prefix: true, allow_nil: true
  validates :subscription_billing_invoice, absence: true

  before_validation :reload_subscription_billing_invoice
  before_destroy :prevent_destroying_invoiced_course

  private

  def reload_subscription_billing_invoice
    subscription&.association(:billing_invoice)&.reset
  end

  def prevent_destroying_invoiced_course
    reload_subscription_billing_invoice
    return unless subscription_billing_invoice

    errors.add(:subscription_billing_invoice, :present)
    throw :abort
  end
end
