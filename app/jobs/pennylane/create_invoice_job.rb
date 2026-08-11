# frozen_string_literal: true

module Pennylane
  class CreateInvoiceJob < ApplicationJob
    retry_on RetryableError, wait: :polynomially_longer, attempts: 8 do |job, error|
      job.arguments.first.fail!(job.arguments.second, error)
    end
    retry_on DocumentPending, wait: 1.minute, attempts: 10 do |job, error|
      job.arguments.first.fail!(job.arguments.second, error)
    end

    def perform(invoice, sync_token)
      return unless invoice.claim!(sync_token)

      CreateInvoice.new(invoice, sync_token:).call
    rescue DocumentPending, RetryableError
      raise if invoice.mark_retrying!(sync_token)
    rescue Error => e
      invoice.fail!(sync_token, e)
    rescue StandardError => e
      invoice.fail!(sync_token, e)
      raise
    end
  end
end
