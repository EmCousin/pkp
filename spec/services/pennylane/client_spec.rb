# frozen_string_literal: true

require 'rails_helper'

describe Pennylane::Client, type: :service do
  subject(:client) { described_class.new(api_token: 'secret', base_url: 'https://pennylane.example.test/api') }

  it 'sends authenticated JSON to the v2 endpoint' do
    response = http_response(Net::HTTPCreated, '201', '{"id":456}')
    allow(client).to receive(:perform_request) do |request, uri|
      expect(uri.to_s).to eq('https://pennylane.example.test/api/customer_invoices')
      expect(request).to be_a(Net::HTTP::Post)
      expect(request['Authorization']).to eq('Bearer secret')
      expect(JSON.parse(request.body)).to eq('customer_id' => 123)
      response
    end

    expect(client.create_invoice(customer_id: 123)).to eq('id' => 456)
  end

  it 'identifies a duplicate external reference returned as 422' do
    response = http_response(
      Net::HTTPUnprocessableEntity,
      '422',
      '{"error":"unprocessable_entity","message":"Duplicate external reference"}'
    )
    allow(client).to receive(:perform_request).and_return(response)

    expect { client.create_invoice(customer_id: 123) }
      .to raise_error(Pennylane::Error, 'Erreur Pennylane (422) : Duplicate external reference') do |error|
        expect(error).to be_duplicate_reference
      end
  end

  it 'identifies duplicate references in the structured 422 details' do
    response = http_response(
      Net::HTTPUnprocessableEntity,
      '422',
      '{"error":"unprocessable_entity","details":{"field":"external_reference","issue":"already exists"}}'
    )
    allow(client).to receive(:perform_request).and_return(response)

    expect { client.create_invoice(customer_id: 123) }.to raise_error(Pennylane::Error) do |error|
      expect(error).to be_duplicate_reference
    end
  end

  it 'turns rate limits into retryable errors' do
    response = http_response(Net::HTTPTooManyRequests, '429', 'Rate limit exceeded')
    allow(client).to receive(:perform_request).and_return(response)

    expect { client.find_invoice('pkp-invoice-1') }.to raise_error(Pennylane::RetryableError)
  end

  def http_response(response_class, code, body)
    response_class.new('1.1', code, '').tap do |response|
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, body)
    end
  end
end
