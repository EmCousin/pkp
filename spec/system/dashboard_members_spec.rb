# frozen_string_literal: true

require 'rails_helper'

describe 'Dashboard member management', type: :system do
  let!(:platform) { create(:platform, domain: 'lvh.me') }
  let!(:user) { create(:user, email: 'parent@example.com', password: 'surprise') }

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

  it 'creates, updates and destroys a member' do
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'surprise'
    click_button 'Connexion'

    expect(page).to have_link('Mes membres')
    click_link 'Mes membres'
    click_link 'Ajouter un membre'

    fill_in 'member_first_name', with: 'Jane'
    fill_in 'member_last_name', with: 'Doe'
    page.execute_script("document.getElementById('member_birthdate').value = '1999-01-01'")
    fill_in 'member_contact_name', with: 'John Doe'
    fill_in 'member_contact_phone_number', with: '0612345678'
    select 'Mère', from: 'member_contact_relationship'
    attach_file 'member_avatar', Rails.root.join('spec/support/file_examples/avatar.jpg'), make_visible: true
    find('label', text: "J'autorise l'utilisation").click
    click_button 'Sauvegarder'

    expect(page).to have_current_path(dashboard_members_path)
    expect(page).to have_text('Élève ajouté·e')
    expect(page).to have_text('Jane Doe')

    click_link 'Modifier'
    fill_in 'member_first_name', with: 'Janet'
    click_button 'Sauvegarder'

    member = Member.find_by!(user:, last_name: 'Doe')
    expect(page).to have_current_path(dashboard_member_path(member))
    expect(page).to have_text('Élève modifié·e')
    expect(page).to have_text('Janet Doe')

    accept_confirm do
      click_button 'Supprimer ce membre'
    end

    expect(page).to have_current_path(dashboard_members_path)
    expect(page).to have_text('Membre supprimé')
    expect(page).to have_no_text('Janet Doe')
    expect(Member).not_to exist(member.id)
  end
end
