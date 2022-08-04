require "rails_helper"

feature "Alumni Workflow", type: :feature do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { build :user }
  let(:member) { build :member, user: user }
  let(:avatar) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')) }

  let(:password) { SecureRandom.hex }

  let(:categories) do
    [
      create(:category, title: 'Adulte',
                        min_age: 16,
                        max_age: 99),
      create(:category, title: 'Adolescent (13 - 15 ans)',
                        min_age: 13,
                        max_age: 15),
      create(:category, title: 'Adolescent (10 - 12 ans)',
                        min_age: 10,
                        max_age: 12),
      create(:category, title: 'Kidz (6 - 7 ans)',
                        min_age: 6,
                        max_age: 7),
      create(:category, title: 'Kidz (8 - 9 ans)',
                        min_age: 8,
                        max_age: 9)
    ]
  end

  let!(:courses) do
    [
      create(:course, title: "Lundi Adulte Féminin",
                      category: categories.first,
                      capacity: 30,
                      weekday: 'lundi'),
      create(:course, title: "Lundi Adulte Mixte",
                      category: categories.first,
                      capacity: 60,
                      weekday: 'lundi'),
      create(:course, title: "Mardi Adulte Mixte",
                      category: categories.first,
                      capacity: 60,
                      weekday: 'mardi'),
      create(:course, title: "Mercredi Adulte Mixte",
                      category: categories.first,
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Jeudi Adulte Mixte",
                      category: categories.first,
                      capacity: 60,
                      weekday: 'jeudi'),
      create(:course, title: "Vendredi Adulte Mixte",
                      category: categories.first,
                      capacity: 60,
                      weekday: 'vendredi'),
      create(:course, title: "Mercredi Ado 13 - 15 ans Mixte",
                      category: categories.second,
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Samedi Ado 13 - 15 ans Mixte",
                      category: categories.second,
                      capacity: 60,
                      weekday: 'samedi'),
      create(:course, title: "Mercredi Ado 10 - 12 ans Mixte",
                      category: categories.third,
                      capacity: 60,
                      weekday: 'mercredi'),
      create(:course, title: "Samedi Ado 10 - 12 ans Mixte",
                      category: categories.third,
                      capacity: 60,
                      weekday: 'samedi'),
      create(:course, title: "Samedi Kidz 6 - 7 ans Mixte",
                      category: categories.fourth,
                      capacity: 60,
                      weekday: 'samedi'),
      create(:course, title: "Samedi Kidz 8 - 9 ans Mixte",
                      category: categories.fifth,
                      capacity: 60,
                      weekday: 'samedi')
    ]
  end

  before do
    travel_to Time.zone.local(Subscription.current_year, 8, 4, 9, 0, 0)
  end

  after do
    travel_back
  end

  scenario "User signs up" do
    visit '/users/sign_up'
    expect(page).to have_text("S'inscrire")
    expect(page).to have_text("C'est les vacances !")
    expect(page).to have_text("Les cours reprennent en septembre. Vous pouvez toujours créer un compte en attendant, nous vous enverrons alors un e-mail pour vous avertir lorsque les inscriptions seront sur le point de réouvrir.")
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
    expect(page).to have_text("Vous n'êtes pas encore inscrit·e pour l'année #{Subscription.current_year} - #{Subscription.next_year} ! Cliquez sur le bouton pour vous inscrire :")
    expect(find_link('Choisir mes cours').visible?).to be true

    click_link 'Choisir mes cours'

    expect(page).to have_text("C'est les vacances")
    expect(page).to have_text("Les cours reprennent en Septembre !")
    expect(page).to have_text("Ouverture des inscriptions le 1er Septembre pour les nouveaux adhérents.")
    expect(page).to have_text("Je suis un·e ancien·ne) élève")

    click_link "Je suis un·e ancien·ne) élève"

    expect(page).to have_text("Accès ancien·ne)s élèves")
    expect(page).to have_text("Entrez l'identifiant et le mot de passe qui vous ont été communiqués par les coachs. Vous pouvez les retrouver dans le mail de réinscription des ancien·ne)s élèves qui vous a été envoyé.")

    fill_in "alumni_access_username", with: Rails.application.credentials.basic_auth[:username]
    fill_in "alumni_access_password", with: Rails.application.credentials.basic_auth[:password]
    click_button 'Envoyer'

    expect(page).to have_text('Veuillez renseigner les informations de la personne à inscrire')
  end
end
