require 'rails_helper'

describe Subscriptions::Validatable, type: :model do
  subject { subscription }

  let(:category) { build :category }
  let(:courses) do
    [
      build(:course, category: category, weekday: Course.weekdays.keys.first),
      build(:course, category: category, weekday: Course.weekdays.keys.last)
    ]
  end
  let(:subscription) { build :subscription, courses: courses }

  it { is_expected.to validate_numericality_of(:fee).is_greater_than_or_equal_to(0) }

  describe 'validating courses' do
    before { subscription.valid? }

    it { expect(subscription).to be_valid }

    describe 'validating the subscription has at least one course' do
      context 'when the subscription has no courses' do
        let(:courses) { [] }

        it { expect(subscription.errors.details[:courses]).to include({ error: :must_exist }) }
      end

      context 'when the subscription has more than three courses' do
        let(:courses) { build_list :course, 4 }

        it { expect(subscription.errors.details[:courses]).to include({ error: :limit_exceeded }) }
      end

      context 'when the subscription has courses from different categories' do
        let(:courses) do
          [
            build(:course),
            build(:course),
          ]
        end

        it { expect(subscription.errors.details[:courses]).to include({ error: :unique_category }) }
      end

      context 'when the subscription has multiple courses the same day' do
        let(:courses) { build_list :course, 2, weekday: Course.weekdays.keys.first }

        it { expect(subscription.errors.details[:courses]).to include({ error: :unique_weekday }) }
      end
    end
  end
end
