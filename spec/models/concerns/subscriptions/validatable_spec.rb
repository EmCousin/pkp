require 'rails_helper'

describe Subscriptions::Validatable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

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

        it { expect(subscription.errors.of_kind?(:courses, :must_exist)).to be true }
      end

      context 'when the subscription has more than three courses' do
        let(:courses) { build_list :course, 4 }

        it { expect(subscription.errors.of_kind?(:courses, :limit_exceeded)).to be true }

        context "when it is winter time" do
          let(:courses) { build_list :course, 3 }
          let(:winter_time) { 1.month.after(Subscription.winter_time_range.first) }

          before do
            travel_to(winter_time)
            subscription.validate
          end

          it { expect(subscription.errors.of_kind?(:courses, :limit_exceeded)).to be true }

          after { travel_back }
        end
      end

      context 'when the subscription has courses from different categories' do
        let(:courses) do
          [
            build(:course),
            build(:course),
          ]
        end

        it { expect(subscription.errors.of_kind?(:courses, :unique_category)).to be true }
      end

      context 'when the subscription has multiple courses the same day' do
        let(:courses) { build_list :course, 2, weekday: Course.weekdays.keys.first }

        it { expect(subscription.errors.of_kind?(:courses, :unique_weekday)).to be true }
      end
    end
  end
end
