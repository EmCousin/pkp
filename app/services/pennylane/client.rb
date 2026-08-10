# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Pennylane
  class Client
    DEFAULT_BASE_URL = 'https://app.pennylane.com/api/external/v2'
    RETRYABLE_STATUSES = [408, 425, 429, *500..599].freeze

    def initialize(
      api_token: Rails.application.credentials.dig(:pennylane, :api_token),
      base_url: Rails.application.credentials.dig(:pennylane, :api_url) || DEFAULT_BASE_URL
    )
      raise Error, 'Le jeton API Pennylane est manquant' if api_token.blank?

      @api_token = api_token
      @base_url = base_url.delete_suffix('/')
    end

    def find_customer(external_reference)
      list('/customers', external_reference).first
    end

    def create_customer(attributes)
      request(:post, '/individual_customers', body: attributes)
    end

    def update_customer(id, attributes)
      request(:put, "/individual_customers/#{id}", body: attributes)
    end

    def find_invoice(external_reference)
      list('/customer_invoices', external_reference).first
    end

    def create_invoice(attributes)
      request(:post, '/customer_invoices', body: attributes)
    end

    def invoice(id)
      request(:get, "/customer_invoices/#{id}")
    end

    def mark_invoice_as_paid(id)
      request(:put, "/customer_invoices/#{id}/mark_as_paid")
    end

    def download(url, redirects: 3)
      raise Error, 'Trop de redirections lors du téléchargement de la facture' if redirects.negative?

      uri = URI(url)
      response = perform_request(Net::HTTP::Get.new(uri), uri)

      download_response(response, uri, redirects)
    end

    private

    def download_response(response, uri, redirects)
      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        download(URI.join(uri, response['location']).to_s, redirects: redirects - 1)
      else
        raise_response_error(response)
      end
    end

    def list(path, external_reference)
      filter = [{ field: 'external_reference', operator: 'eq', value: external_reference }].to_json
      request(:get, path, query: { filter:, limit: 1 }).fetch('items')
    end

    def request(method, path, body: nil, query: nil)
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(query) if query
      response = perform_request(build_request(method, uri, body), uri)
      raise_response_error(response) unless response.is_a?(Net::HTTPSuccess)

      response.body.present? ? JSON.parse(response.body) : nil
    end

    def build_request(method, uri, body)
      request = request_class(method).new(uri)
      request['Authorization'] = "Bearer #{@api_token}"
      request['Content-Type'] = 'application/json'
      request.body = body.to_json if body
      request
    end

    def perform_request(request, uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 20) do |http|
        http.request(request)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
      raise RetryableError, "Pennylane est temporairement indisponible : #{e.message}"
    end

    def request_class(method)
      {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put
      }.fetch(method)
    end

    def raise_response_error(response)
      status = response.code.to_i
      error_class = RETRYABLE_STATUSES.include?(status) ? RetryableError : Error
      response_body = parsed_response_body(response)
      raise error_class.new(
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
