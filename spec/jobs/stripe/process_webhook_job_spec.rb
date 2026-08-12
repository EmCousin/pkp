# frozen_string_literal: true

require 'rails_helper'

describe Stripe::ProcessWebhookJob, type: :job do
  let(:payment_intent_id) { 'pi_test_123' }
  let(:event_type) { 'payment_intent.succeeded' }
  let(:event) do
    Stripe::Event.construct_from(
      id: 'evt_test_123',
      type: event_type,
      data: { object: { id: payment_intent_id } }
    )
  end
  let(:subscription) do
    create(:discovery_registration, discovery_session: create(:discovery_session)).tap do |record|
      record.update!(stripe_payment_intent_id: payment_intent_id)
    end
  end

  before do
    subscription
    allow(Stripe::Event).to receive(:retrieve).with('evt_test_123').and_return(event)
    allow(Subscription).to receive(:find_by).with(stripe_payment_intent_id: payment_intent_id).and_return(subscription)
    allow(subscription).to receive(:reconcile_stripe_payment!)
  end

  it 'reconciles the subscription referenced by the payment intent' do
    described_class.perform_now('evt_test_123')

    expect(subscription).to have_received(:reconcile_stripe_payment!)
  end

  context 'when the event type is not supported' do
    let(:event_type) { 'payment_intent.created' }

    it 'does not reconcile the subscription' do
      described_class.perform_now('evt_test_123')

      expect(subscription).not_to have_received(:reconcile_stripe_payment!)
    end
  end

  context 'when the payment intent does not belong to a subscription' do
    let(:payment_intent_id) { 'pi_unknown' }

    it 'finishes without reconciling a subscription' do
      allow(Subscription).to receive(:find_by).with(stripe_payment_intent_id: payment_intent_id).and_return(nil)

      expect { described_class.perform_now('evt_test_123') }.not_to raise_error
      expect(subscription).not_to have_received(:reconcile_stripe_payment!)
    end
  end
end
