# frozen_string_literal: true

require 'rails_helper'

describe Platform, type: :model do
  subject(:platform) { build(:platform) }

  it { is_expected.to have_many(:members).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:subscriptions).through(:members) }
  it { is_expected.to have_many(:categories).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:courses).through(:categories) }
  it { is_expected.to have_many(:pricings).through(:categories) }
  it { is_expected.to have_many(:camps).dependent(:restrict_with_error) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_numericality_of(:medical_certificate_validity_seasons).only_integer.is_greater_than(0) }

  describe '.current' do
    it 'creates the default platform when none exists' do
      expect { described_class.current }.to change(described_class, :count).by(1)

      expect(described_class.current).to have_attributes(
        name: 'Parkour Paris',
        medical_certificate_validity_seasons: 3
      )
    end

    it 'returns the existing platform' do
      existing_platform = create(:platform, name: 'Parkour Paris')

      expect(described_class.current).to eq(existing_platform)
    end

    it 'does not select another platform as the current Parkour Paris platform' do
      create(:platform, name: 'Another platform')

      expect(described_class.current.name).to eq('Parkour Paris')
    end
  end
end
