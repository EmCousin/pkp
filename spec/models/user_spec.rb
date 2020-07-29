require 'rails_helper'

describe User, type: :model do
  let(:user) { create :user }

  it { is_expected.to have_many(:members).dependent(:destroy) }
  it { is_expected.to have_many(:subscriptions).through(:members) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }

  it { is_expected.to validate_acceptance_of(:terms_of_service) }

  it { is_expected.not_to validate_presence_of(:phone_number).on(:account_setup) }
  it { is_expected.not_to validate_presence_of(:address).on(:account_setup) }
  it { is_expected.not_to validate_presence_of(:zip_code).on(:account_setup) }
  it { is_expected.not_to validate_presence_of(:city).on(:account_setup) }
  it { is_expected.not_to validate_presence_of(:country).on(:account_setup) }

  context "when the user has been confirmed" do
    subject { user }

    before { user.confirm }

    it { is_expected.to validate_presence_of(:phone_number).on(:account_setup) }
    it { is_expected.to validate_presence_of(:address).on(:account_setup) }
    it { is_expected.to validate_presence_of(:zip_code).on(:account_setup) }
    it { is_expected.to validate_presence_of(:city).on(:account_setup) }
    it { is_expected.to validate_presence_of(:country).on(:account_setup) }
  end
end
