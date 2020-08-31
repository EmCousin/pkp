# frozen_string_literal: true

class Category < ApplicationRecord
  MIN_AGE = 1
  MAX_AGE = 100

  has_many :courses, dependent: :restrict_with_error

  validates :title, presence: true,
                    uniqueness: true

  validates :min_age, presence: true,
                      numericality: {
                        only_integer: true,
                        greater_than_or_equal_to: MIN_AGE,
                        less_than: ->(category) { category.max_age }
                      }

  validates :max_age, presence: true,
                      numericality: {
                        only_integer: true,
                        less_than_or_equal_to: MAX_AGE,
                        greater_than: ->(category) { category.min_age }
                      }
end
