require 'rails_helper'

describe Courses::Available, type: :model do
  subject { course }

  let(:active) { true }
  let(:course) { create :course, active: active }

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
    let(:course) { create :course, capacity: capacity, active: active }
    let(:status) { :pending }
    let!(:subscription) { create :subscription, courses: [course], status: status, year: year }

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
        let(:year) { Subscription.current_year + 1 }

        it 'returns an empty list' do
          expect(Course.available(year)).to eq Course.none
        end
      end
    end
  end
end
