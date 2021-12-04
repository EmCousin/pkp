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

      it 'should set the fee to 200' do
        expect(subject.fee).to eq 200
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 300' do
        expect(subject.fee).to eq 300
      end
    end

    context 'when there are 3 courses' do
      let(:count) { 3 }

      it 'should set the fee to 350' do
        expect(subject.fee).to eq 350
      end
    end
  end

  context 'when the category is Adolescent (10 - 12 ans)' do
    let(:category_title) { 'Adolescent (10 - 12 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 200' do
        expect(subject.fee).to eq 200
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 300' do
        expect(subject.fee).to eq 300
      end
    end
  end

  context 'when the category is Adolescent (13 - 15 ans)' do
    let(:category_title) { 'Adolescent (13 - 15 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 200' do
        expect(subject.fee).to eq 200
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 300' do
        expect(subject.fee).to eq 300
      end
    end
  end

  context 'when the category is Kidz (6 - 7 ans)' do
    let(:category_title) { 'Kidz (6 - 7 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 175' do
        expect(subject.fee).to eq 175
      end
    end
  end

  context 'when the category is Kidz (8 - 9 ans)' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 175' do
        expect(subject.fee).to eq 175
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

    it { expect(subject.fee_cents).to eq 17500 }
  end

  describe 'winter pricing' do
    it 'has a constant WINTER_PRICING' do
      expect(described_class::WINTER_PRICING).to eq [180, 230].freeze
    end

    let(:travel_date) { DateTime.new(Time.now.year, 1).end_of_month }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 180' do
        expect(subject.fee).to eq 180
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 230' do
        expect(subject.fee).to eq 230
      end
    end
  end
end
