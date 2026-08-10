# frozen_string_literal: true

module Pennylane
  class SyncMissingInvoicesJob < ApplicationJob
    def perform
      Invoice.recoverable.find_each(&:recover!)
    end
  end
end
