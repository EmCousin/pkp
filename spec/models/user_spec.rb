require 'rails_helper'

describe User, type: :model do
  let(:user) { create :user }

  subject { user }

  it { is_expected.to have_many(:members).dependent(:destroy) }
  it { is_expected.to have_many(:contacts).dependent(:destroy) }
  it { is_expected.to accept_nested_attributes_for(:contacts).allow_destroy(true) }
  it { is_expected.to have_many(:subscriptions).through(:members) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }

  it { is_expected.to validate_acceptance_of(:terms_of_service) }

  it { is_expected.to validate_presence_of(:phone_number).on(:account_setup) }
  it { is_expected.to validate_presence_of(:address).on(:account_setup) }
  it { is_expected.to validate_presence_of(:zip_code).on(:account_setup) }
  it { is_expected.to validate_presence_of(:city).on(:account_setup) }
  it { is_expected.to validate_presence_of(:country).on(:account_setup) }

  describe 'email confirmation' do
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
end
