# frozen_string_literal: true

require 'rails_helper'

describe 'Admin payment proofs', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:admin) { create(:user, :admin, email: 'admin@example.com', password: 'surprise') }
  let!(:member) { create(:member, platform:) }
  let!(:course) { create(:course, category: create(:category, platform:)) }
  let(:payment_proof) { Rack::Test::UploadedFile.new(Rails.root.join('spec/support/file_examples/avatar.jpg')) }
  let!(:subscription) { create(:subscription, member:, courses: [course], payment_proof:) }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }

  around { |example| with_app_host('http://lvh.me') { example.run } }

  it 'removes an erroneous payment proof' do
    visit new_user_session_path
    fill_in 'user_email', with: admin.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'

    visit admin_subscription_path(subscription)
    expect(page).to have_text('Justificatif à vérifier')

    accept_confirm do
      click_button 'Supprimer le justificatif'
    end

    expect(page).to have_current_path(admin_subscription_path(subscription))
    expect(page).to have_text('Justificatif de paiement supprimé')
    expect(page).to have_text('Non payé')
    expect(subscription.reload.payment_proof).not_to be_attached
  end
end
