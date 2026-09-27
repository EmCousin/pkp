# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
describe 'Admin medical certificates', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:admin) { create(:user, :admin, email: 'admin@example.com', password: 'surprise') }
  let!(:member) { create(:member, platform:) }
  let!(:course) { create(:course, category: create(:category, platform:)) }
  let(:medical_certificate) { Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg')) }
  let!(:subscription) do
    create(
      :subscription,
      member:,
      courses: [course],
      terms_accepted_at: Time.current,
      doctor_certified_at: Time.current,
      medical_certificate:
    ).tap { |registered_subscription| registered_subscription.update!(paid_at: Time.current, payment_method: :cash) }
  end

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }

  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'validates a medical certificate, confirming the subscription' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'
    expect(page).to have_text('Bienvenue')

    visit admin_subscription_path(subscription)
    expect(page).to have_text('Certificat à valider')

    click_button 'Valider le certificat'

    expect(page).to have_current_path(admin_subscription_path(subscription))
    expect(page).to have_text('Certificat médical validé')
    expect(page).to have_text('Confirmé')
    expect(subscription.reload.medical_certificate_validated_at).to be_present
    expect(subscription).to be_confirmed
  end

  it 'removes an erroneous medical certificate' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'
    expect(page).to have_text('Bienvenue')

    visit admin_subscription_path(subscription)
    expect(page).to have_text('Certificat à valider')

    accept_confirm do
      click_button 'Supprimer le certificat'
    end

    expect(page).to have_current_path(admin_subscription_path(subscription))
    expect(page).to have_text('Certificat médical supprimé')
    expect(subscription.reload.medical_certificate).not_to be_attached
  end
end
# rubocop:enable Metrics/BlockLength
