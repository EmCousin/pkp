require 'rails_helper'

describe Subscriptions::Decoratable, type: :model do
  subject { subscription }

  let(:course) { build :course, title: 'Lundi Adulte Mixte' }
  let(:another_course) { build :course, title: 'Mardi Adulte Mixte' }
  let(:subscription) { build :subscription, courses: [course, another_course] }

  it { is_expected.to define_enum_for(:status).with_values(%i[pending confirmed archived]) }

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
end
