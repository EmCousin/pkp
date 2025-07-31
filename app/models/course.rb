# frozen_string_literal: true

class Course < ApplicationRecord
  VACATION_MONTHS = (7..8).to_a.freeze
  ALUMNI_MONTHS = VACATION_MONTHS[-1..].freeze

  include Courses::Available

  validates :title, :capacity, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }

  belongs_to :category
  has_many :courses_subscriptions, dependent: :destroy
  has_many :subscriptions, through: :courses_subscriptions
  has_many :members, through: :subscriptions
  has_many :attendance_sheets, dependent: :destroy
  has_many :attendance_records, through: :attendance_sheets

  enum :weekday, lundi: 1, mardi: 2, mercredi: 3, jeudi: 4, vendredi: 5, samedi: 6, dimanche: 7

  scope :featuring_attendance_sheet, -> { where(features_attendance_sheet: true) }
end
