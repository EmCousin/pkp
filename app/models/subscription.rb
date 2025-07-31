# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Subscriptions::Priceable
  include Subscriptions::Payable
  include Subscriptions::Invoiceable
  include Subscriptions::Completable
  include Subscriptions::Filterable
  include Subscriptions::QrEncodeable

  belongs_to :member
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions

  enum :status, pending: 0, confirmed: 1, archived: 2

  after_initialize :set_current_year

  validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :year, presence: true
  validates :member_id, uniqueness: { scope: :year, message: lambda do |subscription, _data|
    I18n.t(
      'custom_error_messages.subscription.member_id.taken',
      full_name: subscription.member.full_name,
      year: subscription.year
    )
  end }

  validate :at_least_one_course?
  validate :maximum_three_courses?
  validate :maximum_two_courses?, on: :create, if: -> { Subscription.winter_time? }
  validate :maximum_one_course?, on: :create, if: -> { Subscription.winter_time? && category_kidz? }
  validate :courses_are_of_the_same_category
  validate :maximum_one_course_per_day
  validate :courses_must_be_available, on: :create

  attr_accessor :category_id

  delegate :kidz?, :teen?, :adult?, to: :category, prefix: true, allow_nil: true

  class << self
    def previous_year
      current_year - 1
    end

    def current_year
      now = Time.current
      now.month < Course::VACATION_MONTHS.first ? now.year - 1 : now.year
    end

    def next_year
      current_year + 1
    end
  end

  def notify_confirmation!
    SubscriptionMailer.confirm_subscription(self).deliver_later
  end

  def season
    "#{year} / #{year + 1}"
  end

  def description
    @description ||= courses.map(&:title).join(', ')
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

  def at_least_one_course?
    errors.add(:courses, :must_exist) if courses.empty?
  end

  def maximum_one_course?
    errors.add(:courses, :limit_exceeded, count: 1) if courses.size > 1
  end

  def maximum_two_courses?
    errors.add(:courses, :limit_exceeded, count: 2) if courses.size > 2
  end

  def maximum_three_courses?
    errors.add(:courses, :limit_exceeded, count: 3) if courses.size > 3
  end

  def courses_are_of_the_same_category
    unique_category = courses.map(&:category).uniq.size == 1

    errors.add(:courses, :unique_category) unless unique_category
  end

  def maximum_one_course_per_day
    weekdays = courses.map(&:weekday)

    errors.add(:courses, :unique_weekday) if weekdays.uniq.size < weekdays.size
  end

  def courses_must_be_available
    errors.add(:courses, :unavailable) if courses.any? { |c| !c.available? }
  end

  def set_current_year
    self.year ||= self.class.current_year
  end
end
