require 'rails_helper'

describe Subscriptions::Payable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { subscription }

  let(:category) { create :category, title: 'Adulte' }
  let(:courses) { create_list :course, 1, category: category }
  let(:subscription) { create :subscription, courses: courses }
  let(:stripe_token) { 'stripe_token' }
  let(:stripe_charge_id) { SecureRandom.hex }
  let(:striped_created_at) { Time.now }
  let(:stripe_amount) { subscription.fee_cents }
  let(:stripe_charge) do
    OpenStruct.new(
      id: stripe_charge_id,
      paid: true,
      created: striped_created_at.to_i,
      amount: stripe_amount
    )
  end

  before do
    freeze_time do
      allow(Stripe::Charge).to receive(:create).with(
        amount: subscription.fee_cents,
        currency: 'eur',
        source: stripe_token,
        description: subscription.description
      ).and_return(stripe_charge)

      allow(Stripe::Charge).to receive(:retrieve).with(
        stripe_charge_id
      ).and_return(stripe_charge)

      subject.pay!(stripe_token)
    end
  end

  it { expect(subject.fee).to eq 175 }

  describe '#pay!' do
    it 'creates a stripe charge id' do
      expect(subject.stripe_charge_id).to eq stripe_charge_id
    end
  end

  describe '#paid?' do
    it { expect(subject.paid?).to be true }

    context "when the stripe amount does not equal the subscription's fee in cents" do
      let(:stripe_amount) { subscription.fee_cents - 1 }

      it { expect(subject.paid?).to be false }
    end
  end

  describe '#paid_at' do
    it { expect(subject.paid_at).to eq Time.at(striped_created_at) }
  end

  describe '#paid_amount' do
    it { expect(subject.paid_amount).to eq (stripe_amount / 100.0) }
  end

  describe '#balance' do
    it { expect(subject.balance).to eq 0 }
  end
end
