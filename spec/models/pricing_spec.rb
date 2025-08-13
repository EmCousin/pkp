require 'rails_helper'

RSpec.describe Pricing, type: :model do
  let(:category) { create :category }

  it { is_expected.to belong_to(:category) }

  describe 'validations' do
    it 'is valid with a proper period and prices' do
      pricing = build :pricing, category: category
      expect(pricing).to be_valid
    end
  end
end


