# frozen_string_literal: true

module Subscriptions
  module Decoratable
    extend ActiveSupport::Concern

    included do
      attr_accessor :category_id

      enum status: { pending: 0, confirmed_bank_check: 1, confirmed_cash: 2, archived: 3 }

      scope :confirmed, -> { confirmed_bank_check.or(confirmed_cash) }
    end

    def confirmed?
      confirmed_cash? || confirmed_bank_check?
    end

    def description
      courses.map(&:title).join(', ')
    end

    def available_courses
      @available_courses = if category_id.present?
                             Course.active.where(category_id:).order(:created_at)
                           else
                             Course.none
                           end
    end

    def suitable_categories
      if member.nil?
        Category.none
      else
        Category.where(
          'min_age <= :age AND max_age >= :age',
          age: member.age(year)
        )
      end
    end

    def category
      @category ||= Category.find_by(id: category_id)
    end

    def status_color
      if confirmed_bank_check?
        'table-success'
      elsif confirmed_cash?
        'table-info'
      elsif archived?
        'table-secondary'
      else
        ''
      end
    end
  end
end
