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

  enum :weekday, lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7

  scope :featuring_attendance_sheet, -> { where(features_attendance_sheet: true) }

  private

  def initialize_capacities_courses
    Member.levels.keys.each do |level|
      capacities_courses.create!(level: level, capacity: 0)
    end
  end
end
