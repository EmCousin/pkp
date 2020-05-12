# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :member, class_name: 'User'
  has_many :courses_subscriptions, dependent: :destroy
  has_many :courses, through: :courses_subscriptions
  has_one :invoice, dependent: :nullify

  validates :year, numericality: { only_integer: true }, presence: true
  validates :fee, numericality: { greater_than_or_equal_to: 0 }, presence: true
  validates :member_id, uniqueness: { scope: :year }
  validate :year_is_current, on: :create
  validate :at_least_one_course?
  validate :maximum_three_courses?
  validate :courses_are_of_the_same_category
  validate :maximum_one_course_per_day

  has_one_attached :signed_form
  has_one_attached :medical_certificate

  enum status: %i[pending confirmed archived]

  def compute_fee
    case [courses.count, courses.first.category]
    when [1, 'Adulte'], [1, 'Adulte Féminin'], [1, 'Adolescent (10 - 12 ans)'], [1, 'Adolescent (13 - 15 ans)'], [1, 'Kidz (6 - 9 ans)'] then 175
    when [2, 'Adulte'] then 285
    when [3, 'Adulte'] then 330
    when [2, 'Adolescent (10 - 12 ans)'], [2, 'Adolescent (13 - 15 ans)'] then 300
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

  private

  def year_is_current
    errors.add(:year, :must_be_current) unless year == Time.now.year
  end

  def at_least_one_course?
    errors.add(:courses, :must_exist) if course_ids.empty?
  end

  def maximum_three_courses?
    errors.add(:courses, :limit_exceeded) if course_ids.count > 3
  end

  def courses_are_of_the_same_category
    unique_category = courses.map(&:category).uniq.size == 1

    errors.add(:courses, :unique_category) unless unique_category
  end

  def maximum_one_course_per_day
    weekdays = courses.map(&:weekday)

    errors.add(:courses, :unique_weekday) unless weekdays.uniq == weekdays
  end

  def stripe_charge
    @stripe_charge ||= stripe_charge_id && Stripe::Charge.retrieve(stripe_charge_id)
  end
end
