# frozen_string_literal: true

module Subscriptions
  module Decoratable
    extend ActiveSupport::Concern

    included do
      attr_accessor :category_id

      enum :status, pending: 0,
                    confirmed: 1,
                    archived: 2
    end

    def season
      "#{year} / #{year + 1}"
    end

    def description
      courses.map(&:title).join(', ')
    end

    def available_courses
      @available_courses ||= category_id.present? ? Course.active.where(category_id:).order(:created_at) : Course.none
    end

    def suitable_categories
      if member.nil?
        Category.none
      else
        Category.suitable_for_age(member.age(year))
      end
    end

    def category
      @category ||= Category.find_by(id: category_id)
    end

    def status_color
      STATUS_COLORS[status.to_sym] || 'text-gray-600'
    end

    def payment_method_color
      PAYMENT_METHOD_COLORS[payment_method&.to_sym] || 'text-gray-600'
    end

    STATUS_COLORS = {
      pending: 'text-yellow-600',
      confirmed: 'text-green-600',
      archived: 'text-red-600'
    }.freeze

    PAYMENT_METHOD_COLORS = {
      bank_check: 'text-indigo-600',
      cash: 'text-blue-600',
      bank_transfer: 'text-purple-600',
      credit_card: 'text-amber-600'
    }.freeze
  end
end
