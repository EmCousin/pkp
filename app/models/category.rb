# frozen_string_literal: true

class Category < ApplicationRecord
  MIN_AGE = 1
  MAX_AGE = 100

  has_many :courses, dependent: :restrict_with_error

  validates :title, presence: true, uniqueness: true

  validates :min_age, presence: true,
                      numericality: {
                        only_integer: true,
                        greater_than_or_equal_to: MIN_AGE
                      }

  validates :min_age, numericality: {
    less_than: ->(category) { category.max_age },
    if: :max_age?
  }

  validates :max_age, presence: true,
                      numericality: {
                        only_integer: true,
                        less_than_or_equal_to: MAX_AGE
                      }

  validates :max_age, numericality: {
    greater_than: ->(category) { category.min_age },
    if: :min_age?
  }

  def kidz?
    max_age <= 9
  end

  def teen?
    min_age > 9 && max_age <= 15
  end

  def adult?
    min_age > 15
  end
end
