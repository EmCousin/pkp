require 'rails_helper'

describe Members::Validatable, type: :model do
  subject { member }

  let(:user) { create :user }
  let(:member) { create :member, user: user }
  let(:too_old_member) { build :member, user: user, birthdate: 100.years.ago }
  let(:too_young_member) { build :member, user: user, birthdate: 5.years.ago }

  describe 'constants' do
    it 'has a constant CONTACTS' do
      expect(described_class::CONTACTS).to eq([
        'Père',
        'Mère',
        'Tuteur / Tutrice',
        'Conjoint(e)',
        'Frère',
        'Sœur',
        'Grand-père',
        'Grand-mère',
        'Oncle',
        'Tante',
        'Cousin(e)',
        'Ami(e)',
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
  it { is_expected.to validate_presence_of(:agreed_to_advertising_right) }

  it 'is expected to validate the birthdate range' do
    expect(member).to be_valid
    expect(member.errors[:birthdate]).to be_empty

    expect(too_old_member).to be_invalid
    expect(too_old_member.errors[:birthdate]).not_to be_empty

    expect(too_young_member).to be_invalid
    expect(too_young_member.errors[:birthdate]).not_to be_empty
  end
end
