# frozen_string_literal: true

module Subscriptions
  module Invoiceable
    extend ActiveSupport::Concern

    included do
      has_one_attached :invoice
      has_many_attached :credit_notes
      has_one :billing_invoice, as: :invoiceable, class_name: 'Billing::Invoice', dependent: :restrict_with_error

      after_save :request_billing_invoice!, if: %i[saved_change_to_paid_at? paid_at?]

      before_validation :reload_billing_invoice, on: :update
      validates :billing_invoice, absence: true, on: :update, if: :billing_attributes_changed?

      attr_accessor :credit_note_amount, :transferring_event
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
        I18n.t('billing.invoice.participant', name: member.full_name),
        I18n.t('billing.invoice.season', start_year: year, end_year: year + 1),
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

    def billing_attributes_changed?
      protected_attributes = %w[fee member_id paid_at year parent_subscription_id discovery_session_id type]
      protected_attributes.delete('discovery_session_id') if transferring_event
      changes_to_save.keys.intersect?(protected_attributes)
    end

    def reload_billing_invoice
      association(:billing_invoice).reset
    end

    def billing_invoice_attributes
      {
        issue_date: Date.current,
        amount: fee,
        label: invoice_label,
        description: invoice_description,
        customer_snapshot: member.user.pennylane_customer_snapshot,
        customer_reference: "pkp-user-#{member.user_id}",
        transaction_reference: invoice_transaction_reference,
        requested_at: Time.current
      }
    end
  end
end
