# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Subscriptions::Priceable
  include Subscriptions::Payable
  include Subscriptions::Invoiceable
  include Subscriptions::Completable
  include Subscriptions::Confirmable
  include Subscriptions::Filterable
  include Subscriptions::QrEncodeable

  belongs_to :member
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions
  has_many :child_subscriptions, class_name: 'Subscription', foreign_key: 'parent_subscription_id', inverse_of: :parent_subscription, dependent: :destroy
  belongs_to :parent_subscription, class_name: 'Subscription', optional: true
  has_one :camps_subscription, dependent: :destroy
  accepts_nested_attributes_for :camps_subscription, reject_if: :all_blank
  has_one :camp, through: :camps_subscription
  delegate :camp, to: :camps_subscription, prefix: :subscription, allow_nil: true

  enum :status, pending: 0, confirmed: 1, archived: 2

  after_initialize :set_current_year

  validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :year, presence: true
  validates :member_id, uniqueness: {
                          scope: :year,
                          message: lambda do |subscription, _data|
                            I18n.t(
                              'custom_error_messages.subscription.member_id.taken',
                              full_name: subscription.member.full_name,
                              year: subscription.year
                            )
                          end
                        },
                        unless: :parent_subscription_id?

  with_options if: :parent_subscription_id? do
    validates :subscription_camp, presence: { if: -> { courses.empty? } }
    validates :courses, presence: { unless: :subscription_camp }
    validates :parent_subscription_member, comparison: { equal_to: :member }
  end

  with_options if: :subscription_camp do
    validates :parent_subscription, presence: true
    validates :courses, absence: true
  end

  with_options unless: :subscription_camp do
    validates :courses, presence: { message: :must_exist }
    validates :courses_count, numericality: { greater_than: 0, message: :must_exist }
    validates :courses_count, numericality: { less_than_or_equal_to: 3, message: :limit_exceeded }
    validates :courses_count, numericality: { less_than_or_equal_to: 2, message: :limit_exceeded, on: :create, if: -> { Subscription.winter_time? } }
    validates :courses_count, numericality: { less_than_or_equal_to: 1, message: :limit_exceeded, on: :create, if: lambda {
      Subscription.winter_time? && category_kidz?
    } }
    validate :courses_are_of_the_same_category
    validate :maximum_one_course_per_day
    validate :courses_must_be_available, on: :create
  end

  attr_accessor :category_id

  delegate :kidz?, :teen?, :adult?, to: :category, prefix: true, allow_nil: true
  delegate :member, to: :parent_subscription, prefix: true, allow_nil: true

  class << self
    def previous_year
      current_year - 1
    end

    def current_year(datetime = Time.current)
      datetime.month < Course::VACATION_MONTHS.first ? datetime.year - 1 : datetime.year
    end

    def next_year
      current_year + 1
    end
  end

  def root_subscription
    parent_subscription&.root_subscription || self
  end

  def build_child_subscription(child_attributes)
    child_subscriptions.new(
      member:,
      year:,
      terms_accepted_at:,
      doctor_certified_at:,
      **child_attributes
    )
  end

  def season
    "#{year} / #{year + 1}"
  end

  def description
    @description ||= if parent_subscription.present? && camp.present?
                       camp.title
                     else
                       courses.map(&:title).join(', ')
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
    @category ||= Category.find_by(id: category_id)
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

  def courses_count
    courses.size
  end

  def courses_are_of_the_same_category
    return if courses.empty? # Skip if no courses

    unique_category = courses.map(&:category).uniq.size == 1

    errors.add(:courses, :unique_category) unless unique_category
  end

  def maximum_one_course_per_day
    return if courses.empty? # Skip if no courses

    weekdays = courses.map(&:weekday)

    errors.add(:courses, :unique_weekday) if weekdays.uniq.size < weekdays.size
  end

  def courses_must_be_available
    return if courses.empty? # Skip if no courses

    errors.add(:courses, :unavailable) if courses.any? { |c| !c.available? }
  end

  def set_current_year
    self.year ||= self.class.current_year
  end
end
