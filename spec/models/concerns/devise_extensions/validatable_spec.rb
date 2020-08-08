require 'rails_helper'

describe DeviseExtensions::Validatable, type: :model do
  subject { user }

  let(:email) { Faker::Internet.email }
  let(:email_confirmation) { email }
  let(:user) { build :user, email: email, email_confirmation: email_confirmation }

  it { is_expected.to respond_to :email_confirmation }
  it { is_expected.to respond_to 'email_confirmation=' }

  it { is_expected.to validate_confirmation_of :email }

  context 'when the user is persisted' do
    let(:user) { create :user, email: email, email_confirmation: email_confirmation }

    it { is_expected.not_to validate_confirmation_of :email }
  end

  context 'when the email confirmation is blank' do
    let(:email_confirmation) { nil }

    it { is_expected.to be_valid }
  end
end
