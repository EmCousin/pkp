# frozen_string_literal: true

require 'rails_helper'

describe 'Stripe webhooks', type: :request do
  let(:webhook_secret) { 'whsec_test' }
  let(:payload) do
    {
      id: 'evt_test_123',
      type: event_type,
      data: { object: { id: stripe_payment_intent_id } }
    }.to_json
  end
  let(:event_type) { 'payment_intent.succeeded' }
  let(:stripe_payment_intent_id) { 'pi_test_123' }
  let(:subscription) { instance_double(Subscription, reconcile_stripe_payment!: true) }
  let(:signature) do
    timestamp = Time.now
    value = Stripe::Webhook::Signature.compute_signature(timestamp, payload, webhook_secret)
    Stripe::Webhook::Signature.generate_header(timestamp, value)
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
    allow(Subscription).to receive(:find_by).with(stripe_payment_intent_id:).and_return(subscription)
  end

  it 'reconciles a valid successful payment event' do
    allow(subscription).to receive(:reconcile_stripe_payment!) do
      expect(Current.platform).to be_nil
    end

    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:ok)
    expect(subscription).to have_received(:reconcile_stripe_payment!)
  end

  it 'acknowledges events that do not require payment reconciliation' do
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_return(Stripe::Event.construct_from(id: 'evt_test_123', type: 'payment_intent.created'))

    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:ok)
    expect(subscription).not_to have_received(:reconcile_stripe_payment!)
  end

  it 'rejects an invalid signature' do
    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => 'invalid' }

    expect(response).to have_http_status(:bad_request)
  end

  it 'asks Stripe to retry while the signing secret is missing' do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(nil)

    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:service_unavailable)
  end

  it 'lets Stripe retry transient reconciliation errors' do
    allow(subscription).to receive(:reconcile_stripe_payment!).and_raise(Stripe::APIConnectionError, 'Unavailable')

    expect do
      post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }
    end.to raise_error(Stripe::APIConnectionError)
  end
end
