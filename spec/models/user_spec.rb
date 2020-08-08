require 'rails_helper'

describe User, type: :model do
  let(:user) { create :user }

  subject { user }

  it { is_expected.to have_many(:members).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:members) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }
end
