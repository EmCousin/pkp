require 'rails_helper'

describe Courses::Available, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { course }

  let(:active) { true }
  let(:category) { create :category, title: 'Adulte' }
  let(:course) { create :course, active: active, category: category }

  describe 'scopes' do
    describe '.active' do
      it "performs a SQL query" do
        expect(Course.active.to_sql).to eq Course.where(active: true).to_sql
      end

      it 'includes the course' do
        expect(Course.active).to include course
      end

      context 'when the course is not active' do
        let(:active) { false }

        it 'does not include the course' do
          expect(Course.active).not_to include course
        end
      end
    end
  end

  describe 'class_methods' do
    let(:year) { Subscription.current_year }
    let(:capacity) { 60 }
    let(:active) { true }
    let(:course) { create :course, capacity:, active:, category: }
    let(:status) { :pending }
    let!(:subscription) { create :subscription, courses: [course], status:, year: }

    describe '.available' do
      it 'includes the course' do
        expect(Course.available(year)).to include course
      end

      context 'when the course has no subscriptions' do
        before { course.subscriptions.destroy_all }

        it 'includes the course' do
          expect(Course.available(year)).to include course
        end
      end

      context 'when the course is not active' do
        let(:active) { false }

        it 'does not include the course' do
          expect(Course.available(year)).not_to include course
        end
      end

      context 'when course is full' do
        let(:capacity) { 1 }

        it 'does not include the course' do
          expect(Course.available(year)).not_to include course
        end

        context 'when the subscription is archived' do
          let(:status) { :archived }

          it 'includes the course' do
            expect(Course.available(year)).to include course
          end
        end

        context "when the year of subscription is in the past" do
          before { subscription.decrement!(:year) }

          it 'includes the course' do
            expect(Course.available(year)).to include course
          end
        end
      end

      context 'when the year is in the future' do
        let(:year) { Subscription.next_year }

        it 'returns an empty list' do
          expect(Course.available(year)).to eq Course.none
        end
      end
    end
  end

  describe '#available_discovery_dates' do
    around { |example| travel_to(Time.zone.local(2026, 9, 1)) { example.run } }

    let(:course) { create(:course, :discoverable, weekday: :samedi) }
    let(:first_date) { course.next_discovery_date }

    it 'offers the weekly dates until the end of the discovery season' do
      expect(course.available_discovery_dates).to include(first_date, first_date + 1.week)
    end

    it 'excludes the given date' do
      expect(course.available_discovery_dates(excluding: first_date)).not_to include(first_date)
    end

    it 'excludes a date whose session is already full' do
      session = DiscoverySession.find_or_create_for_course!(course:, occurs_on: first_date)
      session.update!(capacity: 1)
      create(:discovery_registration, discovery_session: session)

      expect(course.available_discovery_dates).not_to include(first_date)
    end

    it 'excludes a date whose session is closed' do
      DiscoverySession.find_or_create_for_course!(course:, occurs_on: first_date).update!(open: false)

      expect(course.available_discovery_dates).not_to include(first_date)
    end

    it 'returns an empty list when the course does not offer discovery sessions' do
      course.update!(discovery_enabled: false)

      expect(course.available_discovery_dates).to eq([])
    end
  end
end
