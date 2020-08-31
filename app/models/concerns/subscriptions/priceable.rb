# frozen_string_literal: true

module Subscriptions
  module Priceable
    extend ActiveSupport::Concern

    included do
      before_save :set_category_id
      before_save :set_fee
    end

    def fee_cents
      (fee * 100).to_i
    end

    private

    def set_category_id
      self.category_id ||= courses.first.category_id
    end

    def set_fee
      self.fee = pricing[courses.size - 1]
    end

    def pricing
      case category.title
      when 'Adulte'
        [175, 285, 330]
      when 'Adolescent (10 - 12 ans)', 'Adolescent (13 - 15 ans)'
        [175, 300]
      when 'Kidz (6 - 7 ans)', 'Kidz (8 - 9 ans)'
        [175]
      end
    end
  end
end
