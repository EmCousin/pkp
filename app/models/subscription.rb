# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :member
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions

  validates :fee, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :member_id, uniqueness: { scope: :year }
  validate :at_least_one_course?
  validate :maximum_three_courses?
  validate :courses_are_of_the_same_category
  validate :maximum_one_course_per_day

  before_create :set_current_year
  before_save :set_fee

  has_one_attached :signed_form
  has_one_attached :medical_certificate
  has_one_attached :invoice

  enum status: %i[pending confirmed archived]

  attr_accessor :category

  class << self
    def current_year
      now = Time.current
      now.month < Course::VACATION_MONTHS.first ? now.year - 1 : now.year
    end
  end

  def paid?
    return false unless stripe_charge.present?

    stripe_charge.paid && stripe_charge.amount == fee_cents
  end

  def fee_cents
    (fee * 100).to_i
  end

  def description
    courses.pluck(:title).join(', ')
  end

  def paid_at
    Time.at(stripe_charge.created)
  end

  def paid_amount
    stripe_charge.amount / 100.0
  end

  def balance
    fee - paid_amount
  end

  def available_courses
    @available_courses ||= category.present? ? Course.available.where(category: category).order(:created_at) : Course.none
  end

  def completed?
    paid? && signed_form.attached? && medical_certificate.attached?
  end

  private

  def set_fee
    self.fee = compute_fee
  end

  def compute_fee
    case [courses.size, courses.first.category]
    when [1, 'Adulte'], [1, 'Adulte Féminin'], [1, 'Adolescent (10 - 12 ans)'], [1, 'Adolescent (13 - 15 ans)'], [1, 'Kidz (6 - 9 ans)'] then 175
    when [2, 'Adulte'] then 285
    when [3, 'Adulte'] then 330
    when [2, 'Adolescent (10 - 12 ans)'], [2, 'Adolescent (13 - 15 ans)'] then 300
    end
  end

  def set_current_year
    self.year = self.class.current_year
  end

  def at_least_one_course?
    errors.add(:courses, :must_exist) if courses.empty?
  end

  def maximum_three_courses?
    errors.add(:courses, :limit_exceeded) if courses.size > 3
  end

  def courses_are_of_the_same_category
    unique_category = courses.map(&:category).uniq.size == 1

    errors.add(:courses, :unique_category) unless unique_category
  end

  def maximum_one_course_per_day
    weekdays = courses.map(&:weekday)

    errors.add(:courses, :unique_weekday) if weekdays.uniq.size < weekdays.size
  end

  def stripe_charge
    @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
  end
end
