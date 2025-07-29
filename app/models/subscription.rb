# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Subscriptions::Validatable
  include Subscriptions::Decoratable
  include Subscriptions::Priceable
  include Subscriptions::Payable
  include Subscriptions::Invoiceable
  include Subscriptions::Completable
  include Subscriptions::Filterable
  include Subscriptions::QrEncodeable

  belongs_to :member
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions

  delegate :kidz?, :teen?, :adult?, to: :category, prefix: true, allow_nil: true

  def notify_confirmation!
    SubscriptionMailer.confirm_subscription(self).deliver_later
  end
end
