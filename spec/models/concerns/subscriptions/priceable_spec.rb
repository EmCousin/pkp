require 'rails_helper'

describe Subscriptions::Priceable, type: :model do
  subject { subscription }

  let(:category_title) { 'Adulte' }
  let(:category) { create :category, title: category_title }
  let(:count) { 1 }
  let(:courses) { create_list :course, count, category: category }
  let(:subscription) { build :subscription, courses: courses }

  before do
    courses.each_with_index do |course, index|
      course.weekday = index + 1
    end

    subject.save!
  end

  it 'sets the category before save' do
    expect(subject.category_id).to eq category.id
  end

  context 'when the category is adulte' do
    let(:category_title) { 'Adulte' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 175' do
        expect(subject.fee).to eq 175
      end
    end

    context 'when there are 2 courses' do
      let(:count) { 2 }

      it 'should set the fee to 285' do
        expect(subject.fee).to eq 285
      end
    end

    context 'when there are 3 courses' do
      let(:count) { 3 }

      it 'should set the fee to 330' do
        expect(subject.fee).to eq 330
      end
    end
  end

  context 'when the category is Adolescent (10 - 12 ans)' do
    let(:category_title) { 'Adolescent (10 - 12 ans)' }

    context 'when there is 1 course' do
      let(:count) { 1 }

      it 'should set the fee to 175' do
        expect(subject.fee).to eq 175
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

      it 'should set the fee to 175' do
        expect(subject.fee).to eq 175
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

  describe '#fee_cents' do
    let(:category_title) { 'Kidz (8 - 9 ans)' }
    let(:count) { 1 }

    it { expect(subject.fee_cents).to eq 17500 }
  end
end
