# frozen_string_literal: true

class Invoice < ApplicationRecord
  belongs_to :subscription

  validate :subscription_must_be_paid

  has_one_attached :file

  private

  def subscription_must_be_paid
    errors.add(:subscription, :must_be_paid) if subscription.present? && !subscription.paid?
  end
end
