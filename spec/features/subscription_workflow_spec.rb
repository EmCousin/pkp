require "rails_helper"

feature "Subscription Workflow", type: :feature do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { build :user }
  let(:member) { build :member, user: user }
  let(:avatar) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')) }

  let(:password) { SecureRandom.hex }
  let!(:courses) do
    [
      create(:course, title: "Lundi Adulte Féminin",
                      category: "Adulte",
                      capacity: 30,
                      weekday: 'lundi'),
      create(:course, title: "Lundi Adulte Mixte",
                      category: "Adulte",
                      capacity: 60,
                      weekday: 'lundi'),
      create(:course, title: "Mardi Adulte Mixte",
                      category: "Adulte",
                      capacity: 60,
                      weekday: 'mardi'),
      create(:course, title: "Mercredi Adulte Mixte",
                      category: "Adulte",
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Jeudi Adulte Mixte",
                      category: "Adulte",
                      capacity: 60,
                      weekday: 'jeudi'),
      create(:course, title: "Vendredi Adulte Mixte",
                      category: "Adulte",
                      capacity: 60,
                      weekday: 'vendredi'),
      create(:course, title: "Mercredi Ado 13 - 15 ans Mixte",
                      category: "Adolescent (13 - 15 ans)",
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Samedi Ado 13 - 15 ans Mixte",
                      category: "Adolescent (13 - 15 ans)",
                      capacity: 60,
                      weekday: 'samedi'),
      create(:course, title: "Mercredi Ado 10 - 12 ans Mixte",
                      category: "Adolescent (10 - 12 ans)",
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Samedi Ado 10 - 12 ans Mixte",
                      category: "Adolescent (10 - 12 ans)",
                      capacity: 60,
                      weekday: 'samedi'),
      create(:course, title: "Samedi Kidz 6 - 9 ans Mixte",
                      category: "Kidz (6 - 9 ans)",
                      capacity: 60,
                      weekday: 'samedi')
    ]
  end

  before do
    travel_to Time.zone.local(Subscription.current_year, 9, 1, 9, 0, 0)
  end

  after do
    travel_back
  end

  scenario "User signs up" do
    visit '/users/sign_up'
    expect(page).to have_text("S'inscrire")
    expect(page).to have_text("Si vous souhaitez faire un cours d'essai, veuillez envoyer votre demande directement sur notre formulaire de contact.")

    within("#new_user") do
      fill_in "user_email", with: user.email
      fill_in "user_email_confirmation", with: user.email
      fill_in "user_password", with: password
      fill_in "user_password_confirmation", with: password
      check "user_terms_of_service"

      click_button "Inscription"
    end

    expect(page).to have_text("Veuillez compléter votre profil pour continuer")
    expect(page).to have_text("Modifier mon compte")

    within("#edit_user") do
      expect(find_field(id: 'user_email').value).to eq user.email

      fill_in "user_phone_number", with: user.phone_number
      fill_in "user_address", with: user.address
      fill_in "user_zip_code", with: user.zip_code
      fill_in "user_city", with: user.city
      fill_in "user_country", with: user.country
      fill_in "user_current_password", with: password

      click_button "Sauvegarder"
    end

    expect(page).to have_text('Vos modifications ont bien été enregistrées.')
    expect(page).to have_text('Bienvenue !')
    expect(page).to have_text("Vous n'êtes pas encore inscrit(e) pour l'année #{Subscription.current_year} ! Cliquez sur le bouton pour vous inscrire :")
    expect(find_link('Choisir mes cours').visible?).to be true

    click_link 'Choisir mes cours'

    expect(page).to have_text('Veuillez renseigner les informations de la personne à inscrire')

    fill_in "member_first_name", with: member.first_name
    fill_in "member_last_name", with: member.last_name
    fill_in "member_birthdate", with: member.birthdate
    fill_in "member_contact_name", with: member.contact_name
    fill_in "member_contact_phone_number", with: member.contact_phone_number
    select(member.contact_relationship, from: 'member_contact_relationship')
    attach_file('member_avatar', avatar.path)
    check "member_agreed_to_advertising_right"

    click_button 'Sauvegarder'

    expect(page).to have_text('Membre ajouté')
    expect(find_field('subscription_member_id').find('option[selected]').text).to eq member.full_name
    select('Adulte', from: 'subscription_category')

    click_button 'Sauvegarder'

    available_courses = courses.select { |course| course.category == 'Adulte' }
    available_courses.each do |course|
      expect(find_field("subscription_course_ids_#{course.id}").visible?).to be true
    end
    check "subscription_course_ids_#{available_courses.first.id}"
    check "subscription_course_ids_#{available_courses.last.id}"

    click_button 'Sauvegarder'

    expect(page).to have_text('Inscription créée avec succès !')
    expect(page).to have_text('Bienvenue !')
    expect(page).to have_text("Vos inscriptions pour l'année #{Subscription.current_year} :")
    expect(page).to have_text('Ajouter une inscription')
    expect(page).to have_text(available_courses.first.title)
    expect(page).to have_text(available_courses.last.title)
  end
end
