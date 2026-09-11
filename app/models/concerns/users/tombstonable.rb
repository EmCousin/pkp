# frozen_string_literal: true

module Users
  module Tombstonable
    extend ActiveSupport::Concern

    PLACEHOLDER_FIRST_NAME = 'Compte'
    PLACEHOLDER_LAST_NAME = 'A Completer'

    included do
      scope :with_placeholder_name, lambda {
        where(first_name: PLACEHOLDER_FIRST_NAME, last_name: PLACEHOLDER_LAST_NAME)
      }
    end

    def placeholder_name?
      first_name == PLACEHOLDER_FIRST_NAME && last_name == PLACEHOLDER_LAST_NAME
    end
  end
end
