# frozen_string_literal: true

require 'rails_helper'

describe 'Stripe webhooks', type: :request do
  let(:webhook_secret) { 'whsec_test' }
  let(:payload) { { id: 'evt_test_123', type: event_type }.to_json }
  let(:event_type) { 'payment_intent.succeeded' }
  let(:signature) do
    timestamp = Time.now
    value = Stripe::Webhook::Signature.compute_signature(timestamp, payload, webhook_secret)
    Stripe::Webhook::Signature.generate_header(timestamp, value)
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
  end

  it 'queues a valid successful payment event' do
    expect do
      post '/webhooks/stripe', params: payload, headers: { 'Stripe-Signature' => signature }
    end.to have_enqueued_job(Stripe::ProcessWebhookJob).with('evt_test_123')

    expect(response).to have_http_status(:ok)
  end

  it 'acknowledges events that do not require payment reconciliation' do
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_return(Stripe::Event.construct_from(id: 'evt_test_123', type: 'payment_intent.created'))

    expect do
      post '/webhooks/stripe', params: payload, headers: { 'Stripe-Signature' => signature }
    end.not_to have_enqueued_job(Stripe::ProcessWebhookJob)

    expect(response).to have_http_status(:ok)
  end

  it 'rejects an invalid signature' do
    post '/webhooks/stripe', params: payload, headers: { 'Stripe-Signature' => 'invalid' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'asks Stripe to retry while the signing secret is missing' do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(nil)

    post '/webhooks/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:service_unavailable)
  end
end
