require 'rails_helper'

describe Subscriptions::Decoratable, type: :model do
  subject { subscription }

  let(:course) { build :course, title: 'Lundi Adulte Mixte' }
  let(:another_course) { build :course, title: 'Mardi Adulte Mixte' }
  let(:subscription) { build :subscription, courses: [course, another_course] }

  it { is_expected.to respond_to :category_id }
  it { is_expected.to respond_to 'category_id=' }

  it { is_expected.to define_enum_for(:status).with_values(%i[pending confirmed_bank_check confirmed_cash confirmed_bank_transfer archived]) }

  describe '#description' do
    it { expect(subject.description).to eq "Lundi Adulte Mixte, Mardi Adulte Mixte" }
  end

  describe '#available_courses' do
    it "returns no courses since the category is not set" do
      expect(subject.available_courses).to eq Course.none
    end

    context 'when the category is set' do
      let(:category) { create :category }
      let(:subscription) { build :subscription, category_id: category.id }
      let!(:course) { create :course, category: category }

      it "returns the course" do
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
      let(:subscription) { build :subscription, status: :confirmed_bank_check }

      it { expect(subject.status_color).to eq 'text-green-600' }
    end

    context 'when the subscription is archived' do
      let(:subscription) { build :subscription, status: :archived }

      it { expect(subject.status_color).to eq 'text-red-600' }
    end
  end
end
