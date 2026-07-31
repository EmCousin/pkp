# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Subscriptions::Priceable
  include Subscriptions::Payable
  include Subscriptions::Invoiceable
  include Subscriptions::Limitable
  include Subscriptions::Completable
  include Subscriptions::Confirmable
  include Subscriptions::Filterable
  include Subscriptions::QrEncodeable
  include Subscriptions::Seasonable

  belongs_to :member
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
  enum :registration_type, { annual: 0, camp: 1, discovery: 2 }, prefix: true
  enum :attendance_status,
       { present: 'present', absent: 'absent', excused: 'excused' },
       prefix: :attendance

  scope :destruction_protected, lambda {
    event_types = registration_types.values_at('camp', 'discovery')
    where(
      'stripe_payment_intent_id IS NOT NULL OR (registration_type IN (?) AND (paid_at IS NOT NULL OR status = ?))',
      event_types,
      statuses[:confirmed]
    )
  }

  before_validation :infer_registration_type

  validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :member_id, uniqueness: {
                          scope: :year,
                          conditions: -> { registration_type_annual.where(parent_subscription_id: nil) },
                          message: lambda do |subscription, _data|
                            I18n.t(
                              'custom_error_messages.subscription.member_id.taken',
                              full_name: subscription.member.full_name,
                              year: subscription.year
                            )
                          end
                        },
                        if: :annual_root?,
                        on: :create

  with_options if: :parent_subscription_id? do
    validates :parent_subscription_member, comparison: { equal_to: :member }
    validate :parent_subscription_must_be_annual_root
  end

  with_options if: :camp? do
    validates :subscription_camp, presence: true
    validates :courses, absence: true
    validates :discovery_session, absence: true
  end

  with_options if: :discovery? do
    validates :discovery_session, presence: true
    validates :parent_subscription, :subscription_camp, :courses, absence: true
    validate :discovery_session_must_be_available, on: :create
  end

  attr_accessor :category_id

  delegate :kidz?, :teen?, :adult?, to: :category, prefix: true, allow_nil: true
  delegate :member, to: :parent_subscription, prefix: true, allow_nil: true

  def root_subscription
    parent_subscription&.root_subscription || self
  end

  def courses?
    courses.any?
  end

  def camp?
    registration_type_camp?
  end

  def discovery?
    registration_type_discovery?
  end

  def annual?
    registration_type_annual?
  end

  def event?
    camp? || discovery?
  end

  def medical_certificate_required?
    annual?
  end

  def completion_open?
    return year == self.class.current_year if annual?
    return camp.starts_at >= Date.current if camp?

    discovery_session.starts_at >= Time.current
  end

  def build_child_subscription(child_attributes)
    child_subscriptions.new(
      member:,
      year:,
      registration_type: child_attributes[:camps_subscription_attributes].present? ? :camp : :annual,
      terms_accepted_at:,
      doctor_certified_at:,
      **child_attributes
    )
  end

  def description
    @description ||= case registration_type
                     when 'camp' then camp.title
                     when 'discovery' then discovery_session.course.title
                     else courses.map(&:title).join(', ')
                     end
  end

  def available_courses
    @available_courses ||= category_id.present? ? Course.active.where(category_id:).order(:created_at) : Course.none
  end

  def suitable_categories
    if member.nil?
      Category.none
    else
      Category.suitable_for_age(member.age(year))
    end
  end

  def courses_category
    @courses_category ||= courses.first&.category
  end

  def category
    return @category if defined?(@category)

    @category = Category.find_by(id: category_id)
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

  def annual_root?
    annual? && parent_subscription_id.nil?
  end

  def infer_registration_type
    self.registration_type = :camp if subscription_camp.present?
    self.registration_type = :discovery if discovery_session.present?
  end

  def discovery_session_must_be_available
    return unless discovery_session && member
    return if member.can_subscribe_to_discovery?(discovery_session)

    errors.add(:discovery_session, :unavailable)
  end

  def parent_subscription_must_be_annual_root
    return if parent_subscription.annual? && parent_subscription.parent_subscription_id.nil? && parent_subscription.year == year

    errors.add(:parent_subscription, :invalid)
  end
end
