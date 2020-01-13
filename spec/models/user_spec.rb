require 'rails_helper'

describe User, type: :model do
  it { is_expected.to have_many(:subscriptions).dependent(:destroy).with_foreign_key(:member_id) }
end
