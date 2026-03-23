require 'rails_helper'

describe Courses::Available, type: :model do
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
    let(:course) do
      c = create(:course, active:, category:)
      # Set total capacity via capacities_courses
      c.capacities_courses.update_all(capacity: capacity / 4) # Split among 4 levels
      c
    end
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

        before do
          # Set all capacities to small value and then fill with subscriptions
          course.capacities_courses.update_all(capacity: 1)
          # Create a subscription to fill the capacity
          member = create(:member)
          create(:subscription, courses: [course], member: member, year: year, status: :confirmed)
        end

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
end
