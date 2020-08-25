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
      @available_courses = if category_id.present?
                             Course.available.where(category_id: category_id).order(:created_at)
                           else
                             Course.none
                           end
    end
  end
end
