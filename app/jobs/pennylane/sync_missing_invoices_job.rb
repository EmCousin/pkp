# frozen_string_literal: true

module Pennylane
  class SyncMissingInvoicesJob < ApplicationJob
    def perform
      Billing::Invoice.recoverable.find_each(&:recover!)
    end
  end
end
