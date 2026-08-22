# frozen_string_literal: true

require 'rails_helper'

describe 'Event registrations', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:user) { create(:user, email: 'parent@example.com', password: 'surprise') }
  let!(:member) { create(:member, user:, platform:, first_name: 'Jane', last_name: 'Doe') }

  before { driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] }

  around do |example|
    previous_app_host = Capybara.app_host
    previous_always_include_port = Capybara.always_include_port
    Capybara.app_host = 'http://lvh.me'
    Capybara.always_include_port = true

    example.run
  ensure
    Capybara.app_host = previous_app_host
    Capybara.always_include_port = previous_always_include_port
  end

  it 'registers an external member for a discovery session' do
    category = create(:category, platform:, title: 'Découverte adultes')
    course = create(:course, :discoverable, category:, title: 'Cours découverte du samedi')
    discovery_session = create(:discovery_session, course:, price: 25)

    sign_in
    visit dashboard_discovery_sessions_path
    click_link 'Voir la séance'
    click_button "S'inscrire avec #{member.full_name}"

    expect(page).to have_text('Décharge de responsabilité et consentement éclairé')
    registration = DiscoveryRegistration.find_by!(member:, discovery_session:)
    expect(page).to have_current_path(edit_dashboard_subscription_terms_path(registration))
    expect(registration).to have_attributes(fee: 25, parent_subscription: nil)
  end

  it 'registers an annual student for a camp at the student rate' do
    category = create(:category, platform:)
    course = create(:course, category:)
    camp = create(:camp, platform:, title: 'Stage élèves', price: 90, external_price: 140, open: true)
    annual_subscription = create(
      :subscription,
      member:,
      courses: [course],
      status: :confirmed,
      year: camp.year
    )

    sign_in
    visit dashboard_camps_path
    expect(page).to have_text('Réservé aux élèves')
    click_link 'Voir les détails'
    expect(page).to have_text('Tarif élève - 90,00 €')
    click_button "S'inscrire avec #{member.full_name}"

    expect(page).to have_text('Décharge de responsabilité et consentement éclairé')
    registration = CampRegistration.joins(:camp).find_by!(member:, camps: { id: camp.id })
    expect(page).to have_current_path(edit_dashboard_subscription_terms_path(registration))
    expect(registration).to have_attributes(fee: 90, parent_subscription: annual_subscription)
  end

  it 'registers an external member for a camp at the external rate' do
    camp = create(
      :camp,
      platform:,
      title: 'Stage externe',
      price: 90,
      external_price: 140,
      active: false,
      visible_to_externals: true,
      open: false,
      open_to_externals: true
    )

    sign_in
    visit dashboard_camps_path
    expect(page).to have_text('Réservé aux externes')
    click_link 'Voir les détails'
    expect(page).to have_text('Tarif externe - 140,00 €')
    click_button "S'inscrire avec #{member.full_name}"

    expect(page).to have_text('Décharge de responsabilité et consentement éclairé')
    registration = CampRegistration.joins(:camp).find_by!(member:, camps: { id: camp.id })
    expect(page).to have_current_path(edit_dashboard_subscription_terms_path(registration))
    expect(registration).to have_attributes(fee: 140, parent_subscription: nil)
  end

  it 'does not offer an external-only camp to a member with an annual enrollment' do
    category = create(:category, platform:)
    course = create(:course, category:)
    camp = create(
      :camp,
      platform:,
      title: 'Stage externe',
      active: false,
      visible_to_externals: true,
      open: false,
      open_to_externals: true
    )
    create(:subscription, member:, courses: [course], status: :pending, year: camp.year)

    sign_in
    visit dashboard_camp_path(camp)

    expect(page).to have_no_button("S'inscrire avec #{member.full_name}")
    expect(page).to have_text("Ce stage est réservé aux externes. #{member.full_name} possède une inscription annuelle et fait donc partie des élèves.")
  end

  def sign_in
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'
    expect(page).to have_link('Mes membres')
  end
end
