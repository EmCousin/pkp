# frozen_string_literal: true

class Billing < ApplicationRecord
  self.abstract_class = true
  self.table_name_prefix = 'billing_'
end
