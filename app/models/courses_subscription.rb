# frozen_string_literal: true

class CoursesSubscription < ApplicationRecord
  belongs_to :course
  belongs_to :subscription

  validate :subscription_must_not_be_invoiced
  before_create :prevent_saving_invoiced_course
  before_destroy :prevent_destroying_invoiced_course

  private

  def subscription_must_not_be_invoiced
    errors.add(:subscription, :invoiced) if subscription&.billing_invoice
  end

  def prevent_saving_invoiced_course
    lock_subscription
    prevent_change_if_invoiced
  end

  def prevent_destroying_invoiced_course
    lock_subscription
    prevent_change_if_invoiced
  end

  def lock_subscription
    Subscription.lock.where(id: subscription_id).pick(:id)
  end

  def prevent_change_if_invoiced
    return unless Invoice.exists?(invoiceable: subscription)

    errors.add(:subscription, :invoiced)
    throw :abort
  end
end
