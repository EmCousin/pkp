# frozen_string_literal: true

module Pennylane
  class SyncMissingInvoicesJob < ApplicationJob
    def perform
      missing_invoices.find_each { |subscription| CreateInvoiceJob.perform_later(subscription) }
    end

    private

    def missing_invoices
      Subscription.where.not(paid_at: nil)
                  .where.not(pennylane_invoice_requested_at: nil)
                  .where(pennylane_invoice_id: nil, pennylane_invoice_error: nil)
    end
  end
end
