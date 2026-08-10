# frozen_string_literal: true

module Pennylane
  class CreateInvoiceJob < ApplicationJob
    retry_on RetryableError, wait: :polynomially_longer, attempts: 8
    retry_on DocumentPending, wait: 1.minute, attempts: 10 do |job, error|
      job.send(:record_error, job.arguments.first, error)
    end

    def perform(subscription)
      return unless subscription.paid?

      CreateInvoice.new(subscription).call
    rescue DocumentPending
      raise
    rescue StandardError => e
      record_error(subscription, e)
      raise
    end

    private

    def record_error(subscription, error)
      # The failure must remain visible even if mutable registration data no longer validates.
      # rubocop:disable Rails/SkipsModelValidations
      subscription.update_column(:pennylane_invoice_error, error.message.truncate(1000))
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
