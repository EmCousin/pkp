require 'rails_helper'

describe Courses::Validatable, type: :model do
  subject { course }

  let(:course) { build :course }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:capacity) }
end
