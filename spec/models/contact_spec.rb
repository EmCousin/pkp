require 'rails_helper'

describe Contact, type: :model do
  let(:contact) { build :contact }

  subject { contact }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to allow_value('user@example.com').for(:email) }
end
