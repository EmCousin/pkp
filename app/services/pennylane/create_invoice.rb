# frozen_string_literal: true

module Pennylane
  class CreateInvoice
    VAT_MULTIPLIER = BigDecimal('1.2')

    def initialize(invoice, sync_token:, client: Client.new)
      @invoice = invoice
      @sync_token = sync_token
      @client = client
    end

    def call
      return unless invoice.processing?
      raise Error, 'Le paiement de la facture a été annulé' unless subscription.paid?

      external_invoice = synchronize_invoice
      return unless external_invoice

      attach_document(external_invoice)
      invoice.complete!(sync_token, external_invoice)
    end

    private

    attr_reader :client, :invoice, :sync_token

    delegate :invoiceable, to: :invoice
    alias subscription invoiceable

    def synchronize_invoice
      external_invoice = with_customer_lock { find_or_create_external_invoice }
      return unless invoice.record_external!(sync_token, external_invoice)

      external_invoice = client.invoice(invoice.external_id)
      mark_as_paid(external_invoice)
    end

    def mark_as_paid(external_invoice)
      return external_invoice if external_invoice.fetch('paid')

      client.mark_invoice_as_paid(invoice.external_id)
      client.invoice(invoice.external_id)
    end

    def customer_id
      id = user&.pennylane_customer_id || find_or_create_customer.fetch('id')
      user&.update_column(:pennylane_customer_id, id) unless user&.pennylane_customer_id? # rubocop:disable Rails/SkipsModelValidations
      id
    end

    def create_invoice_with_customer
      id = customer_id
      snapshot = customer_attributes
      client.update_customer(id, snapshot)
      find_or_create_invoice(id)
    ensure
      restore_current_customer(user, id) if user && id
    end

    def find_or_create_customer
      find_or_create(:customer, customer_reference) { client.create_customer(customer_attributes) }
    end

    def find_or_create_invoice(customer_id)
      find_or_create(:invoice, invoice_reference) { client.create_invoice(invoice_attributes(customer_id)) }
    end

    def find_external_invoice
      invoice.external_id? ? client.invoice(invoice.external_id) : client.find_invoice(invoice_reference)
    end

    def find_or_create_external_invoice
      external_invoice = find_external_invoice
      if external_invoice
        restore_current_customer(user, customer_id) if user
        external_invoice
      else
        create_invoice_with_customer
      end
    end

    def find_or_create(resource, reference)
      client.public_send("find_#{resource}", reference) || yield
    rescue Error => e
      raise unless e.duplicate_reference?

      client.public_send("find_#{resource}", reference) ||
        raise(RetryableError, "La #{resource} Pennylane existe mais n'est pas encore disponible")
    end

    def customer_attributes
      invoice.customer_snapshot.deep_symbolize_keys.merge(external_reference: customer_reference)
    end

    def current_customer_attributes(user)
      user.pennylane_customer_snapshot.deep_symbolize_keys.merge(external_reference: customer_reference)
    end

    def restore_current_customer(user, id)
      3.times do
        user.reload
        updated_at = user.updated_at
        client.update_customer(id, current_customer_attributes(user))
        return if user.reload.updated_at == updated_at
      end

      raise RetryableError, 'Le client Pennylane a été modifié pendant sa synchronisation'
    end

    def invoice_attributes(customer_id)
      attributes = invoice_header(customer_id).merge(
        pdf_invoice_subject: invoice.label,
        pdf_description: invoice.description,
        invoice_lines: [invoice_line]
      )
      attributes[:transaction_reference] = invoice.transaction_reference.deep_symbolize_keys if invoice.transaction_reference?
      attributes
    end

    def invoice_header(customer_id)
      {
        customer_id:,
        date: invoice.issue_date.iso8601,
        deadline: invoice.issue_date.iso8601,
        currency: invoice.currency,
        language: 'fr_FR',
        draft: false,
        external_reference: invoice_reference
      }
    end

    def invoice_line
      {
        label: invoice.label,
        description: invoice.description,
        quantity: 1,
        unit: 'piece',
        substance: 'services',
        raw_currency_unit_price: price_excluding_tax,
        vat_rate: invoice.vat_rate
      }
    end

    def price_excluding_tax
      (invoice.amount / VAT_MULTIPLIER).round(6).to_s('F')
    end

    def customer_reference
      invoice.customer_reference
    end

    def invoice_reference
      "pkp-invoice-#{invoice.id}"
    end

    def with_customer_lock
      ApplicationRecord.connection_pool.with_connection do |connection|
        namespace = connection.quote('pennylane_customer')
        reference = connection.quote(customer_reference)
        lock = "hashtext(#{namespace}), hashtext(#{reference})"
        connection.execute("SELECT pg_advisory_lock(#{lock})")
        yield
      ensure
        connection.execute("SELECT pg_advisory_unlock(#{lock})") if lock
      end
    end

    def user
      subscription.member.user
    end

    def attach_document(external_invoice)
      document_url = external_invoice['public_file_url']
      raise DocumentPending, 'Le PDF Pennylane est encore en cours de génération' if document_url.blank?

      invoice.document.attach(
        io: StringIO.new(client.download(document_url)),
        filename: "facture-#{external_invoice.fetch('invoice_number')}.pdf",
        content_type: 'application/pdf'
      )
    end
  end
end
