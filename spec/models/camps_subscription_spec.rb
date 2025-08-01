require 'rails_helper'

RSpec.describe CampsSubscription, type: :model do
  it { is_expected.to belong_to(:camp) }
  it { is_expected.to belong_to(:subscription) }

      it { is_expected.to validate_uniqueness_of(:camp_id).scoped_to(:subscription_id) }

  describe 'validations' do
    let(:camp) { create(:camp) }
    let(:course) { create(:course, category: create(:category, title: 'Adulte')) }
    let(:parent_subscription) { create(:subscription, courses: [course]) }
    let(:child_subscription) { create(:subscription, member: parent_subscription.member, year: parent_subscription.year, parent_subscription: parent_subscription) }
    let(:camps_subscription) { build(:camps_subscription, camp: camp, subscription: child_subscription) }

    it 'is valid with valid attributes' do
      expect(camps_subscription).to be_valid
    end

    it 'prevents duplicate subscriptions to the same camp' do
      create(:camps_subscription, camp: camp, subscription: child_subscription)
      duplicate = build(:camps_subscription, camp: camp, subscription: child_subscription)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subscription_id]).to include('already subscribed to this camp')
    end

    it 'requires subscription to be confirmed' do
      child_subscription.update!(status: :pending)
      expect(camps_subscription).not_to be_valid
      expect(camps_subscription.errors[:subscription]).to include('must be confirmed to subscribe to camps')
    end

                it 'validates camp availability' do
      camp.update!(capacity: 1)
      create(:camps_subscription, camp: camp, subscription: child_subscription)

      another_course = create(:course, category: create(:category, title: 'Adulte'))
      another_parent_subscription = create(:subscription, courses: [another_course])

      another_child_subscription = create(:subscription, member: another_parent_subscription.member, year: another_parent_subscription.year, parent_subscription: another_parent_subscription)
      unavailable_camps_subscription = build(:camps_subscription, camp: camp, subscription: another_child_subscription)

      expect(unavailable_camps_subscription).not_to be_valid
      expect(unavailable_camps_subscription.errors[:camp]).to include('is not available for this member')
    end

    it 'prevents subscription if member is already subscribed to this camp' do
      member = child_subscription.member
      create(:camps_subscription, camp: camp, subscription: child_subscription)

      another_course = create(:course, category: create(:category, title: 'Adulte'))
      another_parent_subscription = create(:subscription, member: member, courses: [another_course])

      another_child_subscription = create(:subscription, member: member, year: another_parent_subscription.year, parent_subscription: another_parent_subscription)
      duplicate_member_subscription = build(:camps_subscription, camp: camp, subscription: another_child_subscription)

      expect(duplicate_member_subscription).not_to be_valid
      expect(duplicate_member_subscription.errors[:camp]).to include('is not available for this member')
    end
  end
end
