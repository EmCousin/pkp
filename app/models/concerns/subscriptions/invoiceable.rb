# frozen_string_literal: true

module Subscriptions
  module Invoiceable
    extend ActiveSupport::Concern

    included do
      has_one_attached :invoice
      has_many_attached :credit_notes
      has_one :billing_invoice, as: :invoiceable, class_name: 'Invoice', dependent: :restrict_with_error

      after_save :request_billing_invoice!, if: -> { saved_change_to_paid_at? && paid_at? }

      attr_accessor :credit_note_amount
    end

    def mark_as_not_paid!
      with_lock do
        if billing_invoice
          errors.add(:base, :pennylane_invoice_finalized)
          next false
        end

        super
      end
    end

    def request_billing_invoice!
      with_lock do
        next billing_invoice if billing_invoice
        next unless paid?

        create_billing_invoice!(billing_invoice_attributes)
      end
    end

    def invoice_document
      return billing_invoice.document if billing_invoice&.document&.attached?

      invoice
    end

    def invoice_description
      [
        "Participant : #{member.full_name}",
        "Saison : #{year}-#{year + 1}",
        *invoice_details
      ].join("\n")
    end

    def invoice_transaction_reference
      return unless paid_via_credit_card? && stripe_payment_intent_id?

      {
        banking_provider: 'stripe',
        provider_field_name: 'payment_id',
        provider_field_value: stripe_payment_intent_id
      }
    end

    private

    def billing_invoice_attributes
      {
        issue_date: Date.current,
        amount: fee,
        label: invoice_label,
        description: invoice_description,
        customer_snapshot: member.user.pennylane_customer_snapshot,
        transaction_reference: invoice_transaction_reference,
        requested_at: Time.current
      }
    end
  end
end
