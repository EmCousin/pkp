# frozen_string_literal: true

require 'rails_helper'

describe 'Stripe webhooks', type: :request do
  let(:webhook_secret) { 'whsec_test' }
  let(:payload) do
    {
      id: 'evt_test_123',
      type: event_type,
      data: { object: { id: stripe_payment_intent_id, metadata: stripe_metadata } }
    }.to_json
  end
  let(:event_type) { 'payment_intent.succeeded' }
  let(:stripe_payment_intent_id) { 'pi_test_123' }
  let(:platform) { create(:platform, name: 'Webhook platform') }
  let(:stripe_metadata) { { platform_id: platform.id.to_s } }
  let(:subscription) { instance_double(Subscription, platform:, reconcile_stripe_payment!: true) }
  let(:signature) do
    timestamp = Time.now
    value = Stripe::Webhook::Signature.compute_signature(timestamp, payload, webhook_secret)
    Stripe::Webhook::Signature.generate_header(timestamp, value)
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(webhook_secret)
    allow(Platform).to receive(:find).with(platform.id.to_s).and_return(platform)
    allow(platform.subscriptions).to receive(:find_by).with(stripe_payment_intent_id:).and_return(subscription)
  end

  it 'reconciles a valid successful payment event' do
    allow(subscription).to receive(:reconcile_stripe_payment!) do
      expect(Current.platform).to eq(platform)
    end

    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:ok)
    expect(subscription).to have_received(:reconcile_stripe_payment!)
  end

  it 'does not look outside the platform identified by Stripe metadata' do
    allow(platform.subscriptions).to receive(:find_by).with(stripe_payment_intent_id:).and_return(nil)
    allow(Subscription).to receive(:find_by)

    post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

    expect(response).to have_http_status(:ok)
    expect(Subscription).not_to have_received(:find_by)
    expect(subscription).not_to have_received(:reconcile_stripe_payment!)
  end

  context 'with an in-flight payment intent created before platform metadata was added' do
    let(:stripe_metadata) { {} }

    it 'reconciles the payment using the legacy lookup' do
      allow(Subscription).to receive(:find_by).with(stripe_payment_intent_id:).and_return(subscription)
      allow(subscription).to receive(:reconcile_stripe_payment!) do
        expect(Current.platform).to eq(platform)
      end

      post '/webhook/stripe', params: payload, headers: { 'Stripe-Signature' => signature }

      expect(response).to have_http_status(:ok)
      expect(subscription).to have_received(:reconcile_stripe_payment!)
    end
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
