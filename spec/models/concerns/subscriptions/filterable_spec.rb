require 'rails_helper'

describe Subscriptions::Filterable, type: :model do
  subject { Subscription }

  let(:course) { create :course }

  let!(:confirmed_subscription) { create :subscription, courses: [course], status: :confirmed }
  let!(:pending_subscription) { create :subscription, courses: [course], status: :pending }
  let!(:archived_subscription) { create :subscription, courses: [course], status: :archived }

  describe '#filter_by_status' do
    context 'when selecting the confirmed status' do
      it { expect(subject.filter_by_status('confirmed')).to eq [confirmed_subscription] }
    end

    context 'when selecting the archived status' do
      it { expect(subject.filter_by_status('archived')).to eq [archived_subscription] }
    end

    context 'when selecting the pending status' do
      it { expect(subject.filter_by_status('pending')).to eq [pending_subscription] }
    end

    context 'when selecting is blank' do
      it { expect(subject.filter_by_status('')).to eq [confirmed_subscription, pending_subscription, archived_subscription] }
    end
  end
end
