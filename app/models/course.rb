# frozen_string_literal: true

class Course < ApplicationRecord
  CATEGORIES = ['Adulte', 'Adulte Féminin', 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)', 'Kidz (6 - 9 ans)'].freeze

  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions

  validates :title, :capacity, :category, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :category, inclusion: { in: CATEGORIES }

  enum weekday: { lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7 }

  VACATION_MONTHS = (7..8).to_a.freeze

  def self.available(year)
    now = Time.now
    year -= 1 if now.month > VACATION_MONTHS.last
    return none if year < now.year

    ids = includes(:subscriptions).select do |course|
      course.available?(year)
    end
    ids.any? ? where(id: ids) : none
  end

  def available?(year)
    capacity > subscriptions.count do |subscription|
      !subscription.archived? && subscription.year == year
    end
  end
end
