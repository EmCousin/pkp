# frozen_string_literal: true

class Course < ApplicationRecord
  CATEGORIES = ['Adulte', 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)', 'Kidz (6 - 9 ans)'].freeze

  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions

  validates :title, :capacity, :category, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :category, inclusion: { in: CATEGORIES }

  enum weekday: { lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }

  scope :active, -> { where(active: true) }
  scope :empty, -> { left_outer_joins(:subscriptions).where(subscriptions: { id: nil }) }

  VACATION_MONTHS = (7..8).to_a.freeze
  ALUMNI_MONTHS = VACATION_MONTHS[-1..-1].freeze

  class << self
    def manageable(year = Subscription.current_year)
      with_subscriptions(year).or(empty).distinct
    end

    def with_subscriptions(year = Subscription.current_year)
      left_outer_joins(:subscriptions).where(subscriptions: { year: year })
    end

    def available(year = Subscription.current_year)
      return none if year > Subscription.current_year

      manageable(year).active.where(id: includes(:subscriptions).select do |course|
        course.available?(year)
      end)
    end
  end

  def available?(year = Subscription.current_year)
    availability(year).positive?
  end

  def availability(year = Subscription.current_year)
    capacity - subscriptions.count do |subscription|
      !subscription.archived? && subscription.year == year
    end
  end
end
