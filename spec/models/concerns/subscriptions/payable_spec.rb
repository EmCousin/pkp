require 'rails_helper'

describe Subscriptions::Payable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { subscription }

  let(:user) { create :user }
  let(:member) { create :member, user: }
  let(:discovery_session) { create :discovery_session }
  let(:subscription) do
    create :subscription, member:, registration_type: :discovery, discovery_session:, year: discovery_session.year
  end
  let(:stripe_charge_id) { SecureRandom.hex }
  let(:stripe_payment_intent_id) { 'pi_test_123' }
  let(:stripe_created_at) { Time.now }
  let(:stripe_payment_intent_amount) { subscription.fee_cents }
  let(:stripe_charge_amount) { subscription.fee_cents }
  let(:stripe_status) { 'succeeded' }
  let(:stripe_payment_intent_currency) { 'eur' }
  let(:stripe_charge_currency) { 'eur' }
  let(:stripe_charge_paid) { true }
  let(:stripe_payment_intent) do
    OpenStruct.new(
      id: stripe_payment_intent_id,
      client_secret: 'pi_test_123_secret',
      latest_charge: stripe_charge_id,
      status: stripe_status,
      currency: stripe_payment_intent_currency,
      amount_received: stripe_payment_intent_amount,
      created: stripe_created_at.to_i,
      amount: stripe_payment_intent_amount
    )
  end
  let(:stripe_charge) do
    OpenStruct.new(
      id: stripe_charge_id,
      paid: stripe_charge_paid,
      currency: stripe_charge_currency,
      created: stripe_created_at.to_i,
      amount: stripe_charge_amount
    )
  end

  it { is_expected.to respond_to :payment_proof }

  before do
    freeze_time do
      allow(Stripe::PaymentIntent).to receive(:create).with(
        amount: subscription.fee_cents,
        currency: 'eur',
        description: subscription.description,
        customer: user.stripe_customer_id
      ).and_return(stripe_payment_intent)

      allow(Stripe::PaymentIntent).to receive(:retrieve).with(stripe_payment_intent_id).and_return(stripe_payment_intent)
      allow(Stripe::Charge).to receive(:retrieve).with(stripe_charge_id).and_return(stripe_charge)
      subscription.update_column(:stripe_payment_intent_id, stripe_payment_intent_id)

      subject.verify_stripe_payment!(
        payment_intent_id: stripe_payment_intent_id,
        payment_intent_client_secret: stripe_payment_intent.client_secret,
        redirect_status: 'succeeded'
      )
    end
  end

  describe '#paid?' do
    it { expect(subject.paid?).to be true }
  end

  describe '#paid_at' do
    it { expect(subject.paid_at).to eq Time.at(stripe_created_at) }
  end

  describe '#paid_amount' do
    it { expect(subject.paid_amount).to eq (stripe_charge_amount / 100.0) }
  end

  describe '#balance' do
    it { expect(subject.balance).to eq 0 }
  end

  context 'when Stripe has not confirmed the payment' do
    let(:stripe_status) { 'requires_payment_method' }

    it { expect(subject).not_to be_paid }
  end

  context 'when the payment intent amount differs from the registration fee' do
    let(:stripe_payment_intent_amount) { subscription.fee_cents + 100 }

    it { expect(subject).not_to be_paid }
  end

  context 'when the payment intent currency is not euros' do
    let(:stripe_payment_intent_currency) { 'usd' }

    it { expect(subject).not_to be_paid }
  end

  context 'when the charge amount differs from the registration fee' do
    let(:stripe_charge_amount) { subscription.fee_cents + 100 }

    it { expect(subject).not_to be_paid }
  end

  context 'when the charge currency is not euros' do
    let(:stripe_charge_currency) { 'usd' }

    it { expect(subject).not_to be_paid }
  end

  context 'when Stripe reports an unpaid charge' do
    let(:stripe_charge_paid) { false }

    it { expect(subject).not_to be_paid }
  end

  context 'without a stored payment intent' do
    let(:unstarted_subscription) do
      create :subscription, member: create(:member), registration_type: :discovery, discovery_session:,
                            year: discovery_session.year
    end

    it 'ignores the payment return' do
      expect(Stripe::PaymentIntent).not_to receive(:retrieve)

      unstarted_subscription.verify_stripe_payment!(
        payment_intent_id: stripe_payment_intent_id,
        payment_intent_client_secret: stripe_payment_intent.client_secret,
        redirect_status: 'succeeded'
      )

      expect(unstarted_subscription).not_to be_paid
    end
  end
end
