require 'rails_helper'

describe Subscription, type: :model do
  it { is_expected.to belong_to(:member) }
  it { is_expected.to have_many(:courses_subscriptions).dependent(:destroy) }
  it { is_expected.to have_many(:courses).through(:courses_subscriptions) }

  it { is_expected.to delegate_method(:kidz?).to(:category).with_prefix(true).allow_nil }
  it { is_expected.to delegate_method(:teen?).to(:category).with_prefix(true).allow_nil }
  it { is_expected.to delegate_method(:adult?).to(:category).with_prefix(true).allow_nil }
end
