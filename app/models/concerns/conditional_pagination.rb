# frozen_string_literal: true

module ConditionalPagination
  extend ActiveSupport::Concern

  included do
    scope :paginate_if_active, lambda { |page, active: true, per_page: 25|
      active ? page(page).per(per_page) : all
    }
  end
end
