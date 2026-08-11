# frozen_string_literal: true

module Pennylane
  class Client < Api::Client
    DEFAULT_BASE_URL = 'https://app.pennylane.com/api/external/v2'
    RETRYABLE_STATUSES = [408, 425, 429, *500..599].freeze

    def initialize(
      api_token: Rails.application.credentials.dig(:pennylane, :api_token),
      base_url: Rails.application.credentials.dig(:pennylane, :api_url) || DEFAULT_BASE_URL
    )
      raise Error, 'Le jeton API Pennylane est manquant' if api_token.blank?

      super(
        base_url:,
        headers: {
          'Authorization' => "Bearer #{api_token}",
          'Content-Type' => 'application/json'
        }
      )
    end

    def find_customer(external_reference)
      list('/customers', external_reference).first
    end

    def create_customer(attributes)
      post('/individual_customers', body: attributes)
    end

    def update_customer(id, attributes)
      put("/individual_customers/#{id}", body: attributes)
    end

    def find_invoice(external_reference)
      list('/customer_invoices', external_reference).first
    end

    def create_invoice(attributes)
      post('/customer_invoices', body: attributes)
    end

    def invoice(id)
      get("/customer_invoices/#{id}")
    end

    def mark_invoice_as_paid(id)
      put("/customer_invoices/#{id}/mark_as_paid")
    end

    private

    def list(path, external_reference)
      filter = [{ field: 'external_reference', operator: 'eq', value: external_reference }].to_json
      get(path, query: { filter:, limit: 1 }).fetch('items')
    end

    def connection_error(error)
      RetryableError.new("Pennylane est temporairement indisponible : #{error.message}")
    end

    def redirect_error
      Error.new('Trop de redirections lors du téléchargement de la facture')
    end

    def response_error(response)
      status = response.code.to_i
      error_class = RETRYABLE_STATUSES.include?(status) ? RetryableError : Error
      response_body = parsed_response_body(response)
      error_class.new(
        "Erreur Pennylane (#{status}) : #{response_message(response, response_body)}",
        status:,
        response_body:
      )
    end

    def parsed_response_body(response)
      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    def response_message(response, payload)
      return response.body.presence || response.message unless payload

      payload['message'] || payload['error'] || response.message
    end
  end
end
