# frozen_string_literal: true

class Platform < ApplicationRecord
  DEFAULT_NAME = 'Parkour Paris'
  DEFAULT_MEDICAL_CERTIFICATE_VALIDITY_SEASONS = 3

  has_many :members, dependent: :restrict_with_error
  has_many :subscriptions, through: :members
  has_many :categories, dependent: :restrict_with_error
  has_many :courses, through: :categories
  has_many :pricings, through: :categories
  has_many :discovery_sessions, through: :courses
  has_many :camps, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :medical_certificate_validity_seasons,
            numericality: { only_integer: true, greater_than: 0 }

  def self.current
    find_or_create_by!(name: DEFAULT_NAME) do |platform|
      platform.medical_certificate_validity_seasons = DEFAULT_MEDICAL_CERTIFICATE_VALIDITY_SEASONS
    end
  end
end
