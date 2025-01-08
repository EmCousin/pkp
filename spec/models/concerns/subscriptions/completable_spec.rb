require 'rails_helper'

describe Subscriptions::Completable, type: :model do
  subject { subscription }

  let(:file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec', 'support', 'file_examples', 'example.svg')
    )
  end

  let(:subscription) { build :subscription }

  it { is_expected.to respond_to :form }
  it { is_expected.to respond_to :signed_form }
  it { is_expected.to respond_to :medical_certificate }

  describe '#completed?' do
    before do
      allow(subscription).to receive(:paid?).and_return true
      subscription.signed_form.attach(file)
      subscription.medical_certificate.attach(file)
    end

    it { expect(subscription.completed?).to be true }
  end

  describe '#previous_subscription' do
    let(:member) { create :member }
    let(:course) { create :course }
    let(:subscription) { create :subscription, member: member, courses: [course] }
    let(:year) { subscription.year - 1 }
    let!(:previous_subscription) { create :subscription, member: member, courses: [course], year: year }

    it { expect(subscription.previous_subscription).to eq previous_subscription }

    context 'when the previous subscription is more than 1 year old' do
      let(:year) { subscription.year - 2 }

      it { expect(subscription.previous_subscription).to eq previous_subscription }
    end

    context 'when the previous subscription is more than 2 years old' do
      let(:year) { subscription.year - 3 }

      it { expect(subscription.previous_subscription).to be nil }
    end
  end

  describe '#needs_medical_certificate?' do
    let(:member) { create :member }
    let(:course) { create :course }
    let(:subscription) { create :subscription, member: member, courses: [course] }
    let(:year) { subscription.year - 1 }
    let(:status) { :confirmed_bank_check }
    let!(:previous_subscription) { create :subscription, member: member, courses: [course], year: year, status: status }

    it { expect(subscription.needs_medical_certificate?).to be false }

    context 'when the previous subscription is 2 years old' do
      let(:year) { subscription.year - 2 }

      it { expect(subscription.needs_medical_certificate?).to be false }
    end

    context 'when the previous subscription more than 3 years old' do
      let(:year) { subscription.year - 4 }

      it { expect(subscription.needs_medical_certificate?).to be true }
    end

    context 'when the previous subscription is not confirmed' do
      let(:status) { :pending }

      it { expect(subscription.needs_medical_certificate?).to be true }
    end
  end
end
