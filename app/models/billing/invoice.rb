# frozen_string_literal: true

module Billing
  class Invoice < ApplicationRecord
    self.table_name = 'invoices'

    STALE_AFTER = 15.minutes
    RETRY_STALE_AFTER = 2.hours

    attribute :sync_token, default: -> { SecureRandom.uuid }

    belongs_to :invoiceable, polymorphic: true
    has_one_attached :document

    enum :state, {
      pending: 'pending',
      processing: 'processing',
      retrying: 'retrying',
      completed: 'completed',
      failed: 'failed'
    }

    validates :provider, :state, :issue_date, :amount, :currency, :vat_rate,
              :label, :description, :customer_snapshot, :sync_token, :requested_at, presence: true
    validates :invoiceable_id, uniqueness: { scope: :invoiceable_type }
    validates :external_id, uniqueness: true, allow_nil: true

    scope :recoverable, lambda {
      where(state: %w[pending processing], updated_at: ...STALE_AFTER.ago)
        .or(where(state: :retrying, updated_at: ...RETRY_STALE_AFTER.ago))
    }

    after_create_commit { enqueue(sync_token) }

    def claim!(token)
      with_lock do
        next false unless sync_token == token
        next false unless pending? || retrying?

        update!(state: :processing, error: nil)
      end
    end

    def retry!
      token = with_lock do
        next unless failed?

        rotate_sync!(state: :pending)
      end
      enqueue(token) if token
    end

    def recover!
      token = with_lock do
        next unless recoverable_now?

        rotate_sync!(state: :pending)
      end
      enqueue(token) if token
    end

    def mark_retrying!(token)
      transition_owned_sync(token, state: :retrying, error: nil)
    end

    def fail!(token, exception)
      with_lock do
        next false unless sync_token == token && (processing? || retrying?)

        update!(state: :failed, error: exception.message.truncate(1000))
      end
    end

    def record_external!(token, external_invoice)
      transition_owned_sync(
        token,
        external_id: external_invoice.fetch('id'),
        number: external_invoice['invoice_number']
      )
    end

    def complete!(token, external_invoice)
      transition_owned_sync(
        token,
        state: :completed,
        external_id: external_invoice.fetch('id'),
        number: external_invoice.fetch('invoice_number'),
        completed_at: Time.current,
        error: nil
      )
    end

    private

    def enqueue(token)
      Pennylane::CreateInvoiceJob.perform_later(self, token)
    end

    def recoverable_now?
      ((pending? || processing?) && updated_at <= STALE_AFTER.ago) ||
        (retrying? && updated_at <= RETRY_STALE_AFTER.ago)
    end

    def rotate_sync!(state:)
      token = SecureRandom.uuid
      update!(state:, sync_token: token, error: nil)
      token
    end

    def transition_owned_sync(token, attributes)
      with_lock do
        next false unless processing? && sync_token == token

        update!(attributes)
      end
    end
  end
end
