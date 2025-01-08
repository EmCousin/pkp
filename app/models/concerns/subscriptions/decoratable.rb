# frozen_string_literal: true

module Subscriptions
  module Decoratable
    extend ActiveSupport::Concern

    included do
      attr_accessor :category_id

      enum status: {
        pending: 0,
        confirmed_bank_check: 1,
        confirmed_cash: 2,
        confirmed_bank_transfer: 3,
        archived: 4
      }

      scope :confirmed, -> { where(status: %i[confirmed_bank_check confirmed_cash confirmed_bank_transfer]) }
    end

    def confirmed?
      confirmed_cash? || confirmed_bank_check? || confirmed_bank_transfer?
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
        Category.where('min_age <= :age AND max_age >= :age', age: member.age(year))
      end
    end

    def category
      @category ||= Category.find_by(id: category_id)
    end

    def status_color
      STATUS_COLORS[status.to_sym] || 'text-gray-600'
    end

    STATUS_COLORS = {
      pending: 'text-yellow-600',
      confirmed_bank_check: 'text-green-600',
      confirmed_cash: 'text-blue-600',
      confirmed_bank_transfer: 'text-purple-600',
      archived: 'text-red-600'
    }.freeze
  end
end
