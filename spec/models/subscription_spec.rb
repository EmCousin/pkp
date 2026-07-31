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

  describe '.current_year' do
    it 'keeps the previous season until July 11' do
      expect(described_class.current_year(Date.new(2026, 7, 11))).to eq(2025)
    end

    it 'starts the new season on July 12' do
      expect(described_class.current_year(Date.new(2026, 7, 12))).to eq(2026)
    end
  end

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
              expect(error.options[:count]).to eq 3
                expect(error.options[:value]).to eq 4
                expect(error.options[:message]).to eq :limit_exceeded
              expect(error.message).to eq 'Maximum 3 cours'
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

  describe 'event registrations' do
    let(:member) { create(:member) }

    it 'uses the external camp price without an annual subscription' do
      camp = create(:camp, external_price: 180, open_to_externals: true)
      subscription = build(
        :camp_registration,
        member:,
        year: camp.year,
        camps_subscription_attributes: { camp_id: camp.id }
      )

      expect(subscription.save).to be true
      expect(subscription.fee).to eq(180)
    end

    it 'uses the internal camp price for an annual student' do
      camp = create(:camp, price: 120, external_price: 180)
      annual_subscription = create(:subscription, member:, courses: [create(:course)], status: :confirmed, year: camp.year)
      subscription = annual_subscription.build_child_subscription(camps_subscription_attributes: { camp_id: camp.id })

      expect(subscription.save).to be true
      expect(subscription.fee).to eq(120)
    end

    it 'uses the discovery session price' do
      discovery_session = create(:discovery_session, price: 30)
      subscription = build(:discovery_registration, member:, discovery_session:)

      expect(subscription.save).to be true
      expect(subscription.fee).to eq(30)
    end

    it 'does not require a medical certificate for an event' do
      discovery_session = create(:discovery_session)
      subscription = build(
        :discovery_registration,
        member:,
        discovery_session:,
        terms_accepted_at: Time.current,
        paid_at: Time.current
      )

      expect(subscription).to be_completed
    end

    it 'allows annual enrollment after an external event in the same year' do
      discovery_session = create(:discovery_session)
      create(:discovery_registration, member:, discovery_session:, year: discovery_session.year)

      annual_subscription = build(:subscription, member:, courses: [discovery_session.course], year: discovery_session.year)

      expect(annual_subscription).to be_valid
    end

    it 'keeps the event price as a registration snapshot' do
      discovery_session = create(:discovery_session, price: 30)
      subscription = create(:discovery_registration, member:, discovery_session:)

      discovery_session.update!(price: 45)
      subscription.update!(attendance_status: :present)

      expect(subscription.reload.fee).to eq(30)
    end

    it 'rejects an event registration as an annual parent' do
      discovery_session = create(:discovery_session)
      event_subscription = create(:discovery_registration, member:, discovery_session:)
      annual_subscription = build(:subscription, member:, parent_subscription: event_subscription, courses: [discovery_session.course])

      expect(annual_subscription).not_to be_valid
      expect(annual_subscription.errors.of_kind?(:parent_subscription, :invalid)).to be true
    end

    it 'rejects an event registration for a different season' do
      discovery_session = create(:discovery_session)
      subscription = build(
        :discovery_registration,
        member:,
        discovery_session:,
        year: discovery_session.year - 1
      )

      expect(subscription).not_to be_valid
      expect(subscription.errors.of_kind?(:year, :event_mismatch)).to be true
    end

    it 'does not destroy paid or confirmed event registrations' do
      discovery_session = create(:discovery_session)
      paid = create(:discovery_registration, member:, discovery_session:, paid_at: Time.current)
      confirmed = create(:discovery_registration, member: create(:member),
                                          discovery_session:, status: :confirmed)

      expect(paid.destroy).to be false
      expect(confirmed.destroy).to be false
      expect(paid).to be_persisted
      expect(confirmed).to be_persisted
    end

    it 'cancels an open Stripe payment before destroying a registration' do
      discovery_session = create(:discovery_session)
      subscription = create(:discovery_registration, member:, discovery_session:)
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_test_123').and_return(OpenStruct.new(status: 'requires_payment_method'))
      allow(Stripe::PaymentIntent).to receive(:cancel).with('pi_test_123')

      expect(subscription.destroy).to be subscription
      expect(subscription).not_to be_persisted
      expect(Stripe::PaymentIntent).to have_received(:cancel).with('pi_test_123')
    end

    it 'does not destroy a registration when Stripe cannot cancel its payment' do
      discovery_session = create(:discovery_session)
      subscription = create(:discovery_registration, member:, discovery_session:)
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_test_123').and_return(OpenStruct.new(status: 'processing'))
      allow(Stripe::PaymentIntent).to receive(:cancel).with('pi_test_123').and_raise(Stripe::StripeError, 'Payment is processing')

      expect(subscription.destroy).to be false
      expect(subscription).to be_persisted
    end

    it 'does not cancel Stripe when a finalized registration rejects deletion' do
      discovery_session = create(:discovery_session)
      subscription = create(:discovery_registration, member:, discovery_session:, status: :confirmed)
      subscription.update_column(:stripe_payment_intent_id, 'pi_test_123')
      allow(Stripe::PaymentIntent).to receive(:cancel)

      expect(subscription.destroy).to be false
      expect(Stripe::PaymentIntent).not_to have_received(:cancel)
    end

    it 'destroys a pending unpaid event registration' do
      discovery_session = create(:discovery_session)
      subscription = create(:discovery_registration, member:, discovery_session:)

      expect(subscription.destroy).to be subscription
      expect(subscription).not_to be_persisted
    end

    it 'does not destroy an annual registration with a finalized event child' do
      annual = create(:subscription, member:, courses: [create(:course)], status: :confirmed)
      camp = create(:camp)
      child = annual.build_child_subscription(camps_subscription_attributes: { camp_id: camp.id })
      child.paid_at = Time.current
      child.save!

      expect(annual.destroy).to be false
      expect(annual).to be_persisted
      expect(child.reload).to be_persisted
    end
  end
end
