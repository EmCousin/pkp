require 'rails_helper'

describe User, type: :model do
  let(:user) { create :user }
  let(:too_old_user) { build :user, birthdate: 100.years.ago }
  let(:too_young_user) { build :user, birthdate: 5.years.ago }

  it { is_expected.to have_many(:subscriptions).dependent(:destroy).with_foreign_key(:member_id) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }

  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:birthdate) }
  it { is_expected.to validate_presence_of(:phone_number) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:zip_code) }
  it { is_expected.to validate_presence_of(:city) }
  it { is_expected.to validate_presence_of(:country) }
  it { is_expected.to validate_presence_of(:contact_name) }
  it { is_expected.to validate_presence_of(:contact_phone_number) }
  it { is_expected.to validate_presence_of(:contact_relationship) }
  it { is_expected.to validate_inclusion_of(:contact_relationship).in_array(described_class::CONTACTS) }
  it { is_expected.to validate_presence_of(:agreed_to_publicity_right) }

  it 'is expected to validate the birthdate range' do
    expect(user).to be_valid
    expect(user.errors[:birthdate]).to be_empty

    expect(too_old_user).to be_invalid
    expect(too_old_user.errors[:birthdate]).not_to be_empty

    expect(too_young_user).to be_invalid
    expect(too_young_user.errors[:birthdate]).not_to be_empty
  end

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

  describe '#full_name' do
    it 'returns the first_name followed by the last_name in a proper formatted way' do
      user.first_name = 'mickey'
      user.last_name = 'MoUsE'
      expect(user.full_name).to eq 'Mickey Mouse'
    end
  end
end
