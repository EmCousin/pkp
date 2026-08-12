# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe User, type: :model do
  let(:user) { create :user }

  subject { user }

  it { is_expected.to have_many(:members).dependent(:destroy) }
  it { is_expected.to have_many(:contacts).dependent(:destroy) }
  it { is_expected.to accept_nested_attributes_for(:contacts).allow_destroy(true) }
  it { is_expected.to have_many(:subscriptions).through(:members) }
  it { is_expected.to have_many(:courses).through(:subscriptions) }

  it { is_expected.to validate_acceptance_of(:terms_of_service) }

  it { is_expected.to validate_presence_of(:first_name).on(:account_setup) }
  it { is_expected.to validate_presence_of(:last_name).on(:account_setup) }
  it { is_expected.to validate_presence_of(:phone_number).on(:account_setup) }
  it { is_expected.to validate_presence_of(:address).on(:account_setup) }
  it { is_expected.to validate_presence_of(:zip_code).on(:account_setup) }
  it { is_expected.to validate_presence_of(:city).on(:account_setup) }
  it { is_expected.to validate_presence_of(:country).on(:account_setup) }

  it 'normalizes the billing country to an ISO code' do
    user.country = 'France'

    expect(user.country).to eq('FR')
  end

  it 'normalizes a persisted legacy country before validation' do
    user.update_column(:country, 'France') # rubocop:disable Rails/SkipsModelValidations

    expect(user.reload).to be_valid
    expect(user.country).to eq('FR')
  end

  it 'rejects a country that is not an ISO-3166 alpha-2 code' do
    user.country = 'ZZ'

    expect(user).not_to be_valid
    expect(user.errors.of_kind?(:country, :inclusion)).to be true
  end

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

  it 'does not destroy finalized event registrations' do
    member = create(:member, user:)
    discovery_session = create(:discovery_session)
    subscription = create(:discovery_registration, member:, discovery_session:, paid_at: Time.current)

    expect(user.destroy).to be false
    expect(user).to be_persisted
    expect(subscription.reload).to be_persisted
  end
end
# rubocop:enable Metrics/BlockLength
