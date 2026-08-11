# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Api
  class Client
    REQUEST_CLASSES = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      put: Net::HTTP::Put
    }.freeze

    def initialize(base_url:, headers: {})
      @base_url = base_url.delete_suffix('/')
      @headers = headers
    end

    def download(url, redirects: 3)
      raise redirect_error if redirects.negative?

      uri = URI(url)
      response = perform_request(Net::HTTP::Get.new(uri), uri)

      download_response(response, uri, redirects)
    end

    protected

    def get(path, query: nil)
      request(:get, path, query:)
    end

    def post(path, body: nil)
      request(:post, path, body:)
    end

    def put(path, body: nil)
      request(:put, path, body:)
    end

    private

    def download_response(response, uri, redirects)
      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        download(URI.join(uri, response['location']).to_s, redirects: redirects - 1)
      else
        raise response_error(response)
      end
    end

    def request(method, path, body: nil, query: nil)
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(query) if query
      response = perform_request(build_request(method, uri, body), uri)
      raise response_error(response) unless response.is_a?(Net::HTTPSuccess)

      response.body.present? ? JSON.parse(response.body) : nil
    end

    def build_request(method, uri, body)
      REQUEST_CLASSES.fetch(method).new(uri).tap do |request|
        @headers.each { |name, value| request[name] = value }
        request.body = body.to_json if body
      end
    end

    def perform_request(request, uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 20) do |http|
        http.request(request)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
      raise connection_error(e)
    end

    def connection_error(error)
      StandardError.new("API unavailable: #{error.message}")
    end

    def redirect_error
      StandardError.new('Too many redirects')
    end

    def response_error(response)
      StandardError.new("API request failed with status #{response.code}")
    end
  end
end
