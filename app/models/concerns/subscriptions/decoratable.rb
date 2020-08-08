# frozen_string_literal: true

module Subscriptions
  module Decoratable
    extend ActiveSupport::Concern

    included do
      enum status: %i[pending confirmed archived]
    end

    def description
      courses.map(&:title).join(', ')
    end

    def available_courses
      @available_courses ||= category.present? ? Course.available.where(category: category).order(:created_at) : Course.none
    end
  end
end
