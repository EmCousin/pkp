# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Subscriptions::Priceable
  include Subscriptions::Payable
  include Subscriptions::StripeReconcilable
  include Subscriptions::Invoiceable
  include Subscriptions::Completable
  include Subscriptions::Confirmable
  include Subscriptions::Filterable
  include Subscriptions::QrEncodeable
  include Subscriptions::Seasonable

  belongs_to :member
  has_one :platform, through: :member
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions
  has_many :child_subscriptions, class_name: 'Subscription', foreign_key: 'parent_subscription_id', inverse_of: :parent_subscription, dependent: :destroy
  belongs_to :parent_subscription, class_name: 'Subscription', optional: true
  has_one :camps_subscription, dependent: :destroy
  accepts_nested_attributes_for :camps_subscription, reject_if: :all_blank
  has_one :camp, through: :camps_subscription
  delegate :camp, to: :camps_subscription, prefix: :subscription, allow_nil: true
  belongs_to :discovery_session, optional: true

  enum :status, pending: 0, confirmed: 1, archived: 2
  enum :attendance_status,
       { present: 'present', absent: 'absent', excused: 'excused' },
       prefix: :attendance

  scope :destruction_protected, lambda {
    registrations = left_joins(:billing_invoice)
    event_types = %w[CampRegistration DiscoveryRegistration]

    registrations.where.not(billing_invoices: { id: nil })
                 .or(registrations.where.not(stripe_payment_intent_id: nil))
                 .or(registrations.where(type: event_types).where.not(paid_at: nil))
                 .or(registrations.where(type: event_types, status: statuses[:confirmed]))
  }
  scope :annual_dashboard, lambda {
    where(type: 'AnnualSubscription', year: current_year, parent_subscription_id: nil)
      .not_archived
      .includes(:child_subscriptions, member: { subscriptions: { medical_certificate_attachment: :blob } })
      .with_attached_medical_certificate
  }
  scope :event_dashboard, lambda {
    where(type: %w[CampRegistration DiscoveryRegistration], parent_subscription_id: nil)
      .not_archived
      .includes(:camp, :discovery_session, :member)
      .order(created_at: :desc)
  }
  scope :for_platform, ->(platform) { joins(:member).where(members: { platform_id: platform }) }
  scope :for_discovery_attendance, lambda {
    confirmed
      .includes(member: %i[user avatar_attachment])
      .joins(:member)
      .order('members.first_name', 'members.last_name')
  }

  validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :parent_subscription_member, comparison: { equal_to: :member }, if: :parent_subscription_id?
  validate :parent_subscription_must_be_annual_root, if: :parent_subscription_id?
  validate :member_must_belong_to_current_platform, if: %i[member current_platform?]
  validate :member_cannot_change, on: :update, if: :will_save_change_to_member_id?
  validate :courses_must_belong_to_member_platform, if: %i[member courses?]
  delegate :member, to: :parent_subscription, prefix: true, allow_nil: true

  def root_subscription
    parent_subscription&.root_subscription || self
  end

  def courses?
    courses.any?
  end

  def event?
    false
  end

  def medical_certificate_required?
    false
  end

  def invoice_details
    []
  end

  def status_color
    STATUS_COLORS[status.to_sym] || 'text-gray-600'
  end

  def payment_method_color
    PAYMENT_METHOD_COLORS[payment_method&.to_sym] || 'text-gray-600'
  end

  STATUS_COLORS = {
    pending: 'text-yellow-600',
    confirmed: 'text-green-600',
    archived: 'text-red-600'
  }.freeze

  PAYMENT_METHOD_COLORS = {
    bank_check: 'text-indigo-600',
    cash: 'text-blue-600',
    bank_transfer: 'text-purple-600',
    credit_card: 'text-amber-600'
  }.freeze

  private

  def parent_subscription_must_be_annual_root
    return if parent_subscription.is_a?(AnnualSubscription) && parent_subscription.parent_subscription_id.nil? && parent_subscription.year == year

    errors.add(:parent_subscription, :invalid)
  end

  def courses_must_belong_to_member_platform
    subscription_courses = courses.to_a
    ActiveRecord::Associations::Preloader.new(records: subscription_courses, associations: :category).call
    return if subscription_courses.all? { |course| course.category&.platform_id == member.platform_id }

    errors.add(:courses, :wrong_platform)
  end

  def member_must_belong_to_current_platform
    errors.add(:member, :wrong_platform) unless member.platform == Current.platform
  end

  def member_cannot_change
    errors.add(:member, :locked)
  end

  def current_platform?
    Current.platform.present?
  end
end
