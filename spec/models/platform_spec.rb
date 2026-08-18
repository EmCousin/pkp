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
  it { is_expected.to validate_presence_of(:domain) }
  it { is_expected.to validate_uniqueness_of(:domain).ignoring_case_sensitivity }
  it { is_expected.to validate_numericality_of(:medical_certificate_validity_seasons).only_integer.is_greater_than(0) }

  describe 'domain normalization' do
    it 'strips whitespace and lowercases the domain' do
      platform.domain = ' ParkourParis.FR '

      expect(platform.tap(&:validate).domain).to eq('parkourparis.fr')
    end
  end
end
