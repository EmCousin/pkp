# frozen_string_literal: true

module Auth
  class ApplicationRecord < ::ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = 'auth_'
  end
end
