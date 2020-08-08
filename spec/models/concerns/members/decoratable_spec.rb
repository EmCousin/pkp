require 'rails_helper'

describe Members::Decoratable, type: :model do
  subject { member }

  let(:member) { build :member, first_name: 'mickey', last_name: 'MoUse' }

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
end
