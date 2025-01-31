require 'rails_helper'

describe Subscriptions::Priceable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject { subscription }

  let(:category_title) { 'Adulte' }
  let(:category) { create :category, title: category_title }
  let(:count) { 1 }
  let(:courses) { create_list :course, count, category: category }
  let(:subscription) { build :subscription, courses: courses }
  let(:travel_date) { DateTime.new(Time.now.year, 9).end_of_month }

  before do
    travel_to travel_date

    courses.each_with_index do |course, index|
      course.weekday = index + 1
    end

    subject.save!

    travel_back
  end

  it 'sets the category before save' do
    expect(subject.category_id).to eq category.id
  end

  context 'when the category is adulte' do
    let(:category_title) { 'Adulte' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end

    context 'when there are 3 courses' do
      let(:count) { 3 }

      it 'should set the fee to 420' do
        expect(subject.fee).to eq 420
      end
    end
  end

  context 'when the category is Adolescent (10 - 12 ans)' do
    let(:category_title) { 'Adolescent (10 - 12 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end
  end

  context 'when the category is Adolescent (13 - 15 ans)' do
    let(:category_title) { 'Adolescent (13 - 15 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 240' do
        expect(subject.fee).to eq 240
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 360' do
        expect(subject.fee).to eq 360
      end
    end
  end

  context 'when the category is Kidz (6 - 7 ans)' do
    let(:category_title) { 'Kidz (6 - 7 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 210' do
        expect(subject.fee).to eq 210
      end
    end
  end

  context 'when the category is Kidz (8 - 9 ans)' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 210' do
        expect(subject.fee).to eq 210
      end
    end
  end

  describe '.winter_time?' do
    let(:current_time) { DateTime.new(Subscription.current_year, 9).end_of_month }

    it { travel_to(current_time) { expect(Subscription.winter_time?).to be false } }

    context 'when it is between December 20 and July 1st' do
      let(:current_time) { DateTime.new(Subscription.current_year, 12, 30).end_of_day }

      it { travel_to(current_time) { expect(Subscription.winter_time?).to be true } }
    end
  end

  describe '#fee_cents' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }
    let(:count) { 1 }

    it { expect(subject.fee_cents).to eq 21000 }
  end

  describe 'spring pricing' do
    let(:travel_date) { DateTime.new(Time.now.year, 4).end_of_month }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 120' do
        expect(subject.fee).to eq 145
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 215' do
        expect(subject.fee).to eq 215
      end
    end

    context 'when the category is Adolescent (10 - 12 ans)' do
      let(:category_title) { 'Adolescent (10 - 12 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 145' do
          expect(subject.fee).to eq 145
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 215' do
          expect(subject.fee).to eq 215
        end
      end
    end

    context 'when the category is Adolescent (13 - 15 ans)' do
      let(:category_title) { 'Adolescent (13 - 15 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 145' do
          expect(subject.fee).to eq 145
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 215' do
          expect(subject.fee).to eq 215
        end
      end
    end

    context 'when the category is Kidz (6 - 7 ans)' do
      let(:category_title) { 'Kidz (6 - 7 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 120' do
          expect(subject.fee).to eq 120
        end
      end
    end

    context 'when the category is Kidz (8 - 9 ans)' do
      let(:category_title) { 'Kidz (8 - 9 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 120' do
          expect(subject.fee).to eq 120
        end
      end
    end
  end

  describe 'winter pricing' do
    let(:travel_date) { DateTime.new(Time.now.year, 1).end_of_month }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 205' do
        expect(subject.fee).to eq 205
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 275' do
        expect(subject.fee).to eq 275
      end
    end

    context 'when the category is Adolescent (10 - 12 ans)' do
      let(:category_title) { 'Adolescent (10 - 12 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 205' do
          expect(subject.fee).to eq 205
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 275' do
          expect(subject.fee).to eq 275
        end
      end
    end

    context 'when the category is Adolescent (13 - 15 ans)' do
      let(:category_title) { 'Adolescent (13 - 15 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 205' do
          expect(subject.fee).to eq 205
        end
      end

      context 'when there are 2 courses' do
        let(:count) { 2 }

        it 'should set the fee to 275' do
          expect(subject.fee).to eq 275
        end
      end
    end

    context 'when the category is Kidz (6 - 7 ans)' do
      let(:category_title) { 'Kidz (6 - 7 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 155' do
          expect(subject.fee).to eq 155
        end
      end
    end

    context 'when the category is Kidz (8 - 9 ans)' do
      let(:category_title) { 'Kidz (8 - 9 ans)' }

      context 'when there is 1 course' do
        let(:count) { 1 }

        it 'should set the fee to 155' do
          expect(subject.fee).to eq 155
        end
      end
    end
  end
end
