# frozen_string_literal: true

module Courses
  module Validatable
    extend ActiveSupport::Concern

    included do
      validates :title, :capacity, presence: true
      validates :capacity, numericality: { greater_than_or_equal_to: 1, only_integer: true }
    end
  end
end
