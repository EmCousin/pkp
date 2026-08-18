require 'rails_helper'

RSpec.describe Pricing, type: :model do
  let(:category) { create :category }

  it { is_expected.to belong_to(:category) }

  describe 'validations' do
    it 'is valid with a proper period and prices' do
      pricing = build :pricing, category: category
      expect(pricing).to be_valid
    end

    it 'does not move a pricing to a category on another platform' do
      pricing = create(:pricing, category:)
      other_platform = create(:platform, name: 'Other platform')
      other_category = create(:category, platform: other_platform, title: 'Other category')

      expect(pricing.update(category: other_category)).to be false
      expect(pricing.errors.of_kind?(:category, :platform_locked)).to be true
    end
  end
end
