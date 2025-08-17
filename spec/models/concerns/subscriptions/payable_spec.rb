require 'rails_helper'

describe Subscriptions::Payable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { subscription }

  let(:category) { create :category, title: 'Adulte' }
  let(:courses) { create_list :course, 1, category: category }
  let(:subscription) { create :subscription, courses: courses }
  let(:stripe_charge_id) { SecureRandom.hex }
  let(:stripe_payment_intent_id) { 'pi_test_123' }
  let(:stripe_created_at) { Time.now }
  let(:stripe_amount) { subscription.fee_cents }
  let(:stripe_payment_intent) do
    OpenStruct.new(
      id: stripe_payment_intent_id,
      client_secret: 'pi_test_123_secret',
      latest_charge: stripe_charge_id,
      paid: true,
      created: stripe_created_at.to_i,
      amount: stripe_amount
    )
  end
  let(:stripe_charge) do
    OpenStruct.new(
      id: stripe_charge_id,
      paid: true,
      created: stripe_created_at.to_i,
      amount: stripe_amount
    )
  end

  it { is_expected.to respond_to :payment_proof }

  before do
    freeze_time do
      allow(Stripe::PaymentIntent).to receive(:create).with(
        amount: subscription.fee_cents,
        currency: 'eur',
        description: subscription.description
      ).and_return(stripe_payment_intent)

      allow(Stripe::Charge).to receive(:retrieve).with(stripe_charge_id).and_return(stripe_charge)

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
    it { expect(subject.paid_amount).to eq (stripe_amount / 100.0) }
  end

  describe '#balance' do
    it { expect(subject.balance).to eq 0 }
  end
end
