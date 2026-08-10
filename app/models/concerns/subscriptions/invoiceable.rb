# frozen_string_literal: true

module Subscriptions
  module Invoiceable
    extend ActiveSupport::Concern

    included do
      has_one_attached :invoice
      has_many_attached :credit_notes

      before_save :request_pennylane_invoice, if: :being_paid?
      after_save_commit :enqueue_pennylane_invoice, if: :just_paid?

      validates :pennylane_invoice_id, uniqueness: true, allow_nil: true

      attr_accessor :credit_note_amount
    end

    def mark_as_not_paid!
      if pennylane_invoice_id?
        errors.add(:base, :pennylane_invoice_finalized)
        return false
      end

      super
    end

    private

    def being_paid?
      will_save_change_to_paid_at? && paid_at?
    end

    def just_paid?
      saved_change_to_paid_at? && paid_at?
    end

    def request_pennylane_invoice
      self.pennylane_invoice_requested_at = Time.current
      self.pennylane_invoice_error = nil
    end

    def enqueue_pennylane_invoice
      Pennylane::CreateInvoiceJob.perform_later(self)
    end
  end
end
