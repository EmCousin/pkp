# frozen_string_literal: true

class Platform < ApplicationRecord
  has_many :members, dependent: :restrict_with_error
  has_many :subscriptions, through: :members
  has_many :categories, dependent: :restrict_with_error
  has_many :courses, through: :categories
  has_many :pricings, through: :categories
  has_many :discovery_sessions, through: :courses
  has_many :attendance_sheets, through: :courses
  has_many :attendance_records, through: :attendance_sheets
  has_many :camps, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :domain, presence: true, uniqueness: true
  validates :medical_certificate_validity_seasons,
            numericality: { only_integer: true, greater_than: 0 }

  normalizes :domain, with: ->(domain) { domain.strip.downcase }
end
