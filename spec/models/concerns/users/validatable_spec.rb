require 'rails_helper'

describe Users::Validatable, type: :model do
  let(:user) { build :user }

  subject { user }

  it { is_expected.to validate_acceptance_of(:terms_of_service) }

  it { is_expected.to validate_presence_of(:phone_number).on(:account_setup) }
  it { is_expected.to validate_presence_of(:address).on(:account_setup) }
  it { is_expected.to validate_presence_of(:zip_code).on(:account_setup) }
  it { is_expected.to validate_presence_of(:city).on(:account_setup) }
  it { is_expected.to validate_presence_of(:country).on(:account_setup) }
end
