# frozen_string_literal: true

module ConditionalPagination
  extend ActiveSupport::Concern

  included do
    scope :paginate_if_active, lambda { |page, active: true|
      active ? page(page).per(1) : all
    }
  end
end
