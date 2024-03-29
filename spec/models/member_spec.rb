require 'rails_helper'

describe Member, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:contacts).through(:user) }
  it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }
  it { is_expected.to respond_to(:avatar) }
end
