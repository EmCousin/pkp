# frozen_string_literal: true

module Courses
  module Validatable
    extend ActiveSupport::Concern

    CATEGORIES = [
      'Adulte',
      'Adolescent (13 - 15 ans)',
      'Adolescent (10 - 12 ans)',
      'Kidz (6 - 9 ans)'
    ].freeze

    included do
      validates :title, :capacity, :category, presence: true
      validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
      validates :category, inclusion: { in: CATEGORIES }
    end
  end
end
