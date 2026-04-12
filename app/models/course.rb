# frozen_string_literal: true

class Course < ApplicationRecord
  VACATION_MONTHS = (7..8).to_a.freeze
  ALUMNI_MONTHS = VACATION_MONTHS[-1..].freeze

  include Courses::Available

  belongs_to :category
  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions
  has_many :attendance_sheets, dependent: :destroy
  has_many :attendance_records, through: :attendance_sheets
  has_many :capacities_courses, dependent: :destroy

  accepts_nested_attributes_for :capacities_courses, allow_destroy: true

  validates :title, presence: true

  enum :weekday, lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7

  scope :featuring_attendance_sheet, -> { where(features_attendance_sheet: true) }

  # Virtual attribute for backward compatibility with existing tests
  # Sets all level capacities to the same value
  def capacity=(value)
    capacities_courses.each do |cap|
      # rubocop:disable Rails/SkipsModelValidations
      cap.update_column(:capacity, value / capacities_courses.count)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  # Returns total capacity across all levels
  def capacity
    capacities_courses.sum(:capacity)
  end
end
