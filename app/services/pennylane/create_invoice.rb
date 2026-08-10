# frozen_string_literal: true

module Pennylane
  # Provider IDs must be persisted even if mutable registration data no longer validates.
  # rubocop:disable Rails/SkipsModelValidations
  class CreateInvoice
    VAT_RATE = 'FR_200'
    VAT_MULTIPLIER = BigDecimal('1.2')

    def initialize(subscription, client: Client.new)
      @subscription = subscription
      @client = client
    end

    def call
      return unless subscription.paid?

      invoice = synchronize_invoice
      attach_invoice(invoice)
      record_success
    end

    private

    attr_reader :client, :subscription

    def synchronize_invoice
      invoice = find_or_create_invoice(customer_id)
      persist_invoice(invoice)
      invoice = client.invoice(subscription.pennylane_invoice_id)
      mark_as_paid(invoice)
    end

    def mark_as_paid(invoice)
      return invoice if invoice.fetch('paid')

      client.mark_invoice_as_paid(subscription.pennylane_invoice_id)
      client.invoice(subscription.pennylane_invoice_id)
    end

    def customer_id
      user = subscription.member.user
      id = user.pennylane_customer_id || find_or_create_customer(user).fetch('id')
      user.update_column(:pennylane_customer_id, id) unless user.pennylane_customer_id?
      client.update_customer(id, customer_attributes(user))
      id
    end

    def find_or_create_customer(user)
      find_or_create(:customer, customer_reference(user)) { client.create_customer(customer_attributes(user)) }
    end

    def find_or_create_invoice(customer_id)
      return client.invoice(subscription.pennylane_invoice_id) if subscription.pennylane_invoice_id?

      find_or_create(:invoice, invoice_reference) { client.create_invoice(invoice_attributes(customer_id)) }
    end

    def find_or_create(resource, reference)
      send("find_#{resource}", reference) || yield
    rescue Error => e
      raise unless e.conflict?

      send("find_#{resource}", reference) ||
        raise(RetryableError, "La #{resource} Pennylane existe mais n'est pas encore disponible")
    end

    def find_customer(reference)
      client.find_customer(reference)
    end

    def find_invoice(reference)
      client.find_invoice(reference)
    end

    # rubocop:disable Metrics/MethodLength
    def customer_attributes(user)
      {
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone_number,
        emails: [user.email],
        external_reference: customer_reference(user),
        billing_language: 'fr_FR',
        payment_conditions: 'upon_receipt',
        billing_address: billing_address(user)
      }
    end

    def invoice_attributes(customer_id)
      issue_date = Date.current.iso8601
      {
        customer_id:,
        date: issue_date,
        deadline: issue_date,
        currency: 'EUR',
        language: 'fr_FR',
        draft: false,
        external_reference: invoice_reference,
        pdf_invoice_subject: invoice_label,
        pdf_description: invoice_description,
        invoice_lines: [{
          label: invoice_label,
          description: invoice_description,
          quantity: 1,
          unit: 'piece',
          substance: 'services',
          raw_currency_unit_price: price_excluding_tax,
          vat_rate: VAT_RATE
        }]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def billing_address(user)
      {
        address: user.address,
        postal_code: user.zip_code,
        city: user.city,
        country_alpha2: user.country
      }
    end

    def invoice_label
      case subscription
      when DiscoveryRegistration then "Cours découverte - #{subscription.description}"
      when CampRegistration then "Stage - #{subscription.description}"
      else "Cours annuels #{subscription.year}-#{subscription.year + 1} - #{subscription.description}"
      end
    end

    def invoice_description
      ([participant_details] + event_details).join("\n")
    end

    def participant_details
      "Participant : #{subscription.member.full_name}\nSaison : #{subscription.year}-#{subscription.year + 1}"
    end

    def event_details
      case subscription
      when DiscoveryRegistration
        ["Date : #{I18n.l(subscription.discovery_session.occurrence_date, format: :long)}"]
      when CampRegistration
        camp_details
      else
        []
      end
    end

    def camp_details
      dates = "Dates : du #{I18n.l(subscription.camp.starts_at, format: :long)} " \
              "au #{I18n.l(subscription.camp.ends_at, format: :long)}"
      rate = subscription.parent_subscription_id? ? 'Tarif interne' : 'Tarif externe'
      [dates, rate]
    end

    def price_excluding_tax
      (subscription.fee.to_d / VAT_MULTIPLIER).round(6).to_s('F')
    end

    def customer_reference(user)
      "pkp-user-#{user.id}"
    end

    def invoice_reference
      "pkp-subscription-#{subscription.id}"
    end

    def persist_invoice(invoice)
      subscription.update_columns(
        pennylane_invoice_id: invoice.fetch('id'),
        pennylane_invoice_number: invoice['invoice_number'],
        pennylane_invoice_error: nil
      )
    end

    def attach_invoice(invoice)
      document_url = invoice['public_file_url']
      raise DocumentPending, 'Le PDF Pennylane est encore en cours de génération' if document_url.blank?

      subscription.invoice.attach(
        io: StringIO.new(client.download(document_url)),
        filename: "facture-#{invoice.fetch('invoice_number')}.pdf",
        content_type: 'application/pdf'
      )
    end

    def record_success
      subscription.update_columns(pennylane_invoice_error: nil, pennylane_invoiced_at: Time.current)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
