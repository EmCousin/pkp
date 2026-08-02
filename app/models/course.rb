# frozen_string_literal: true

class Course < ApplicationRecord
  VACATION_MONTHS = (7..8).to_a.freeze
  VACATION_START_DAY = 12
  ALUMNI_MONTHS = VACATION_MONTHS[-1..].freeze

  include Courses::Available

  validates :title, :capacity, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  with_options if: :discovery_enabled? do
    validates :discovery_price, presence: true, numericality: { greater_than: 0 }
    validates :discovery_capacity, presence: true,
                                   numericality: { greater_than_or_equal_to: 1, only_integer: true }
  end

  belongs_to :category
  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions
  has_many :attendance_sheets, dependent: :destroy
  has_many :attendance_records, through: :attendance_sheets
  has_many :discovery_sessions, dependent: :restrict_with_error

  enum :weekday, lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7

  scope :featuring_attendance_sheet, -> { where(features_attendance_sheet: true) }
  scope :discoverable, -> { active.where(discovery_enabled: true) }

  def self.vacation_start(year = Time.current.year)
    Time.zone.local(year, VACATION_MONTHS.first, VACATION_START_DAY).beginning_of_day
  end

  def discovery_season_end(reference_date = Date.current)
    season_year = reference_date < self.class.vacation_start(reference_date.year).to_date ? reference_date.year - 1 : reference_date.year
    1.day.before(self.class.vacation_start(season_year + 1)).to_date
  end

  def next_discovery_date(from: Date.current)
    date = from + ((self.class.weekdays.fetch(weekday) - from.cwday) % 7)
    date if date <= discovery_season_end(from)
  end

  def discovery_date_available?(date, today: Date.current)
    active? && discovery_enabled? && date.between?(today, discovery_season_end(today)) &&
      date.cwday == self.class.weekdays.fetch(weekday)
  end
end
