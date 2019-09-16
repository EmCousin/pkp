class Course < ApplicationRecord
  CATEGORIES = ['Adulte', 'Adolescent (13 - 15 ans)', 'Adolescent (10 - 12 ans)', 'Kidz (6 - 9 ans)'].freeze

  validates :title, :capacity, :category, presence: true

  validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }

  validates :category, inclusion: { in: CATEGORIES }
end