require 'rails_helper'

describe Member, type: :model do
  subject { member }

  let(:user) { create :user }
  let(:member) { create :member, user: user, first_name: 'mickey', last_name: 'MoUse' }
  let(:too_old_member) { build :member, user: user, birthdate: 100.years.ago }
  let(:too_young_member) { build :member, user: user, birthdate: 5.years.ago }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:contacts).through(:user) }
  it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }
  it { is_expected.to respond_to(:avatar) }

  describe 'constants' do
    it 'has a constant CONTACTS' do
      expect(described_class::CONTACTS).to eq([
        'Père',
        'Mère',
        'Tuteur / Tutrice',
        'Conjoint·e',
        'Frère',
        'Sœur',
        'Grand-père',
        'Grand-mère',
        'Oncle',
        'Tante',
        'Cousin·e',
        'Ami·e',
        'Autre'
      ].freeze)
    end
  end

  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:birthdate) }
  it { is_expected.to validate_presence_of(:contact_name) }
  it { is_expected.to validate_presence_of(:contact_phone_number) }
  it { is_expected.to validate_presence_of(:contact_relationship) }
  it { is_expected.to validate_inclusion_of(:contact_relationship).in_array(described_class::CONTACTS) }

  it { is_expected.to delegate_method(:email).to(:user) }
  it { is_expected.to delegate_method(:phone_number).to(:user) }
  it { is_expected.to delegate_method(:address).to(:user) }
  it { is_expected.to delegate_method(:zip_code).to(:user) }
  it { is_expected.to delegate_method(:city).to(:user) }
  it { is_expected.to delegate_method(:country).to(:user) }

  describe '#full_name' do
    it 'returns the first_name followed by the last_name in a proper formatted way' do
      expect(subject.full_name).to eq 'Mickey Mouse'
    end
  end

  it 'is expected to validate the birthdate range' do
    expect(member).to be_valid
    expect(member.errors[:birthdate]).to be_empty

    expect(too_old_member).to be_invalid
    expect(too_old_member.errors[:birthdate]).not_to be_empty

    expect(too_young_member).to be_invalid
    expect(too_young_member.errors[:birthdate]).not_to be_empty
  end

  describe '#can_subscribe?' do
    let(:camp) { create(:camp) }
    let(:member) { create(:member) }
    let(:subscription) { create(:subscription, member: member, status: :confirmed) }

    it 'returns true when all conditions are met' do
      expect(camp.can_subscribe?(member)).to be_truthy
    end

    it 'returns false when camp is fully booked' do
      camp.update!(capacity: 1)
      create(:camps_subscription, camp: camp, subscription: subscription)
      expect(camp.can_subscribe?(member)).to be_falsey
    end

    it 'returns false when member has no confirmed subscription' do
      subscription.update!(status: :pending)
      expect(camp.can_subscribe?(member)).to be_falsey
    end

    it 'returns false when member is already subscribed to this camp' do
      create(:camps_subscription, camp: camp, subscription: subscription)
      expect(camp.can_subscribe?(member)).to be_falsey
    end
  end
end
