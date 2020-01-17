require 'rails_helper'

describe User, type: :model do
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
  it {is_expected.to validate_inclusion_of(:contact_relationship).in_array(described_class::CONTACTS) }
  it { is_expected.to validate_presence_of(:agreed_to_publicity_right) }

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
    it 'returns the first_name followed by the last_name' do
      user = described_class.new
      user.first_name = 'Mickey'
      user.last_name = 'Mouse'
      expect(user.full_name).to eq 'Mickey Mouse'
    end
  end
end
