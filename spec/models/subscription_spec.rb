require 'rails_helper'

describe Subscription, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it { is_expected.to belong_to(:member) }
  it { is_expected.to have_many(:courses_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:courses).through(:courses_subscriptions) }

  it { is_expected.to define_enum_for(:status).with_values(%i[pending confirmed archived]) }

  it { is_expected.to respond_to :category_id }
  it { is_expected.to respond_to 'category_id=' }

  it { is_expected.to delegate_method(:kidz?).to(:category).with_prefix(true).allow_nil }
  it { is_expected.to delegate_method(:teen?).to(:category).with_prefix(true).allow_nil }
  it { is_expected.to delegate_method(:adult?).to(:category).with_prefix(true).allow_nil }

  describe 'validatable' do
    subject { subscription }

    let(:category) { create :category }
    let(:courses) do
      [
        build(:course, category: category, weekday: Course.weekdays.keys.first),
        build(:course, category: category, weekday: Course.weekdays.keys.last)
      ]
    end
    let(:subscription) { build :subscription, courses: courses, category_id: category.id }

    it { is_expected.to validate_numericality_of(:fee).is_greater_than_or_equal_to(0) }

    describe 'validating courses' do
      before { subscription.valid? }

      it { expect(subscription).to be_valid }

      describe 'validating the subscription has at least one course' do
        context 'when the subscription has no courses' do
          let(:courses) { [] }

          it 'invalidates the subscription' do
            expect(subscription.errors.of_kind?(:courses, :blank)).to be true
          end
        end

        context 'when the subscription has more courses than allowed' do
          context 'when the category has pricings' do
            let(:pricings_count) { 5 }
            let(:prices) { pricings_count.times.map { |i| (i + 1) * 100 } }
            let!(:category) { create(:category) }
            let!(:pricing) { create(:pricing, category: category, prices: prices) }
            let(:courses) { build_list :course, pricings_count + 1, category: category }
            let(:subscription) { build :subscription, courses: courses, category_id: category.id }

            before do
              # Clear memoized courses_category and re-validate
              subscription.instance_variable_set(:@courses_category, nil)
              subscription.valid?
            end

            it 'invalidates the subscription' do
              error = subscription.errors.first
              expect(error.type).to eq :less_than_or_equal_to
              expect(error.attribute).to eq :courses_count
              expect(error.options[:count]).to eq pricings_count
              expect(error.options[:value]).to eq pricings_count + 1
              expect(error.options[:message]).to eq :limit_exceeded
              expect(error.message).to eq "Maximum #{pricings_count} cours"
            end
          end

          context 'when the category has no pricings' do
            let(:category) { build(:category, pricings: []) }

            context 'when the subscription has more than three courses' do
              let(:courses) { build_list :course, 4, category: }

              it 'invalidates the subscription' do
                error = subscription.errors.first
                expect(error.type).to eq :less_than_or_equal_to
                expect(error.attribute).to eq :courses_count
                expect(error.options[:count]).to eq 2
                expect(error.options[:value]).to eq 4
                expect(error.options[:message]).to eq :limit_exceeded
                expect(error.message).to eq 'Maximum 2 cours'
              end
            end

            context 'when it is winter time' do
              let(:courses) do
                [
                  build(:course, category:, weekday: 1),
                  build(:course, category:, weekday: 2),
                  build(:course, category:, weekday: 3)
                ]
              end
              let(:winter_time) { 1.month.after(Subscription.winter_time_range.first) }

              before do
                travel_to(winter_time)
                subscription.validate
              end

              it 'invalidates the subscription' do
                error = subscription.errors.first
                expect(error.type).to eq :less_than_or_equal_to
                expect(error.attribute).to eq :courses_count
                expect(error.options[:count]).to eq 2
                expect(error.options[:value]).to eq 3
                expect(error.options[:message]).to eq :limit_exceeded
                expect(error.message).to eq 'Maximum 2 cours'
              end

              context 'when the subscription is for Kidz' do
                let(:category) { create :category, :kidz }
                let(:courses) do
                  [
                    build(:course, category: category, weekday: 1),
                    build(:course, category: category, weekday: 2)
                  ]
                end

                before do
                  travel_to(winter_time)
                  subscription.validate
                end

                it 'invalidates the subscription' do
                  error = subscription.errors.first
                  expect(error.type).to eq :less_than_or_equal_to
                  expect(error.attribute).to eq :courses_count
                  expect(error.options[:count]).to eq 1
                  expect(error.options[:value]).to eq 2
                  expect(error.options[:message]).to eq :limit_exceeded
                  expect(error.message).to eq 'Maximum 1 cours'
                end
              end
            end
          end
        end

        context 'when the subscription has courses from different categories' do
          let(:courses) do
            [
              build(:course),
              build(:course)
            ]
          end

          it { expect(subscription.errors.of_kind?(:courses, :unique_category)).to be true }
        end

        context 'when the subscription has multiple courses the same day' do
          let(:courses) { build_list :course, 2, weekday: Course.weekdays.keys.first }

          it { expect(subscription.errors.of_kind?(:courses, :unique_weekday)).to be true }
        end

        context 'when the subscription has courses that are no longer available' do
          let(:courses) { build_list :course, 2, weekday: Course.weekdays.keys.first, capacity: 0 }

          it { expect(subscription.errors.of_kind?(:courses, :unavailable)).to be true }
        end
      end
    end
  end

  describe 'decoratable' do
    subject { subscription }

    let(:course) { build :course, title: 'Lundi Adulte Mixte' }
    let(:another_course) { build :course, title: 'Mardi Adulte Mixte' }
    let(:subscription) { build :subscription, courses: [course, another_course] }

    describe '#description' do
      it { expect(subject.description).to eq 'Lundi Adulte Mixte, Mardi Adulte Mixte' }
    end

    describe '#available_courses' do
      it 'returns no courses since the category is not set' do
        expect(subject.available_courses).to eq Course.none
      end

      context 'when the category is set' do
        let(:category) { create :category }
        let(:subscription) { build :subscription, category_id: category.id }
        let!(:course) { create :course, category: category }

        it 'returns the course' do
          expect(subject.available_courses).to include course
        end
      end
    end

    describe '#category' do
      let(:category) { create :category }
      let(:subscription) { build :subscription, category_id: category.id }

      it { expect(subject.category).to eq category }
    end

    describe '#status_color' do
      it { expect(subject.status_color).to eq 'text-yellow-600' }

      context 'when the subscription is confirmed' do
        let(:subscription) { build :subscription, status: :confirmed }

        it { expect(subject.status_color).to eq 'text-green-600' }
      end

      context 'when the subscription is archived' do
        let(:subscription) { build :subscription, status: :archived }

        it { expect(subject.status_color).to eq 'text-red-600' }
      end
    end
  end
end
