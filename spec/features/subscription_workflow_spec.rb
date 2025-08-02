require "rails_helper"

feature "Subscription Workflow", type: :feature do
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

  let!(:camp) { create(:camp, title: 'Stage Nature', starts_at: 1.month.from_now, ends_at: 1.month.from_now + 5.days, active: true) }

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
    expect(page).to have_text("Vous n'êtes pas encore inscrit·e pour l'année #{Subscription.current_year} - #{Subscription.next_year} ! Cliquez sur le bouton pour vous inscrire :")
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

    expect(page).to have_text('Élève ajouté·e')
    expect(find_field('subscription_member_id').find('option[selected]').text).to eq member.full_name
    select(categories.first.title, from: 'subscription_category_id')

    click_button 'Continuer'

    available_courses = categories.first.courses
    available_courses.each do |course|
      expect(find_field("subscription_course_ids_#{course.id}").visible?).to be true
    end
    check "subscription_course_ids_#{available_courses.first.id}"
    check "subscription_course_ids_#{available_courses.last.id}"

    click_button 'Continuer'

    # After creating subscription, user is redirected to terms page
    expect(page).to have_text("Inscription #{Subscription.current_year} / #{Subscription.next_year}")
    expect(page).to have_text('En complétant cette inscription, je reconnais avoir pris connaissance des conditions d\'inscription et je certifie que les informations de l\'élève sont correctes.')

    # Accept terms
    check "subscription_terms_accepted"
    click_button 'Sauvegarder'

    # After accepting terms, user is redirected to medical certificate page
    expect(page).to have_text('Pour valider votre inscription, vous devez avoir un certificat médical autorisant la pratique du Parkour délivré par un médecin.')

    # Accept medical certificate
    check "subscription_medical_certificate"
    click_button 'Sauvegarder'

    # After medical certificate, user is redirected to payment page
    expect(page).to have_text('Payer par carte bancaire')

                                        # Verify we're on the payment page
    expect(page).to have_text('Payer par carte bancaire')
    expect(page).to have_text('Paiement par carte bancaire')

    # The payment form should be present
    expect(page).to have_selector('form[data-stripe-target="form"]')

                # Mock Stripe payment for testing
    stripe_charge = OpenStruct.new(
      id: 'ch_test_123',
      paid: true,
      created: Time.current.to_i,
      amount: 36000  # 360.00 EUR in cents
    )

    allow(Stripe::Charge).to receive(:create).with(
      amount: 36000,
      currency: 'eur',
      source: 'tok_test_123',
      description: anything
    ).and_return(stripe_charge)

            # Submit the form with the stripe token parameter
    # This simulates what happens when Stripe creates a token and submits the form
    form = find('form[data-stripe-target="form"]')
    page.driver.submit form[:method], form[:action], { stripeToken: 'tok_test_123' }

    # After successful payment, should redirect to dashboard with success message
    expect(page).to have_text('Inscription payée avec succès !')
    expect(page).to have_text('Bienvenue !')
    expect(page).to have_text("Vos inscriptions pour l'année #{Subscription.current_year} :")
    expect(page).to have_text('Ajouter une inscription')
    expect(page).to have_text(available_courses.first.title)
    expect(page).to have_text(available_courses.last.title)

    expect(page).to have_text('Parcourir les stages')
    click_link 'Parcourir les stages'

    expect(page).to have_text('Stage Nature')
    click_link 'Voir les détails'

    expect(page).to have_text('Choisissez un membre pour vous inscrire')
    click_button "S'inscrire avec #{member.full_name}"

    expect(page).to have_text('Joindre un justificatif de paiement')
    attach_file('subscription[payment_proof]', avatar.path) # dummy file
    click_button 'Sauvegarder'

    expect(page).to have_text('Justificatif de paiement ajouté avec succès')
  end
end
