# frozen_string_literal: true

module Subscriptions
  module Invoiceable
    extend ActiveSupport::Concern

    included do
      has_one_attached :invoice
      has_many_attached :credit_notes

      attr_accessor :credit_note_amount
    end
  end
end
