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

  describe '#filter_by_discovery_session_id' do
    let(:discovery_session) { create(:discovery_session, course:, starts_at: 1.month.from_now) }
    let!(:discovery_registration) { create(:discovery_registration, discovery_session:) }

    it 'returns registrations for the selected discovery session' do
      expect(subject.filter_by_discovery_session_id(discovery_session.id)).to eq([discovery_registration])
    end

    it 'returns all subscriptions when no session is selected' do
      expect(subject.filter_by_discovery_session_id(nil)).to include(
        confirmed_subscription,
        pending_subscription,
        archived_subscription,
        discovery_registration
      )
    end
  end
end
