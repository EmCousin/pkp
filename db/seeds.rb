# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

## Default user

DiscoverySession.destroy_all
Camp.destroy_all
Subscription.destroy_all
Course.destroy_all
Category.destroy_all
Member.destroy_all
User.destroy_all

platform = Platform.current

user = User.new
user.email = "monemail@mail.fr"
user.first_name = "Maria"
user.last_name = "Silva"
user.phone_number = "+33299506779"
user.email_confirmation = "monemail@mail.fr"
user.password = "s3cr3tp4$$w0rd"
user.address = "1 rue des Halles"
user.zip_code = "75001"
user.city = "Paris"
user.country = "France"
user.admin = true
user.terms_of_service = true

member = user.members.new
member.platform = platform
member.first_name = "Maria"
member.last_name = "Silva"
member.birthdate = 20.years.ago
member.agreed_to_advertising_right = true
member.avatar = Rack::Test::UploadedFile.new(Rails.root.join('public', 'pkp.jpg'), "image/jpeg")
member.contact_name = "Maria"
member.contact_phone_number = "+33299506779"
member.contact_relationship = Member::CONTACTS.sample

user.save

## Default courses

categories = {
  adults: platform.categories.create!(title: "Adultes (16 ans et +)", min_age: 16, max_age: 100),
  teens: platform.categories.create!(title: "Ados (10 - 15 ans)", min_age: 10, max_age: 15),
  kids: platform.categories.create!(title: "Kidz (6 - 9 ans)", min_age: 6, max_age: 9),
  health: platform.categories.create!(title: "Parkour Santé", min_age: 16, max_age: 100)
}

course_description = <<~DESCRIPTION
  Cours extérieur de parkour à Paris, encadré par des coachs diplômés.
  Les séances comprennent un échauffement, une préparation physique et mentale,
  des ateliers techniques et la mise en pratique du parkour. Les lieux alternent
  entre Bercy, Austerlitz et Olympiades selon l'agenda.
DESCRIPTION

courses = {}

weekdays = {
  monday: :lundi,
  tuesday: :mardi,
  wednesday: :mercredi,
  thursday: :jeudi,
  friday: :vendredi
}

weekdays.each do |weekday, enum_value|
  courses["adult_#{weekday}".to_sym] = Course.create!(
    title: "Parkour Adults - #{weekday.to_s.capitalize} (19h00 - 20h30)",
    description: "#{course_description}\nCours mixte adultes, à partir de 16 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
    capacity: 30,
    weekday: enum_value,
    category: categories[:adults],
    features_attendance_sheet: true
  )
end

courses[:adult_saturday] = Course.create!(
  title: "Parkour Adultes - Samedi (9h30 - 10h45)",
  description: "#{course_description}\nCours mixte adultes, à partir de 16 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
  capacity: 30,
  weekday: :samedi,
  category: categories[:adults],
  features_attendance_sheet: true
)

courses[:adult_women] = Course.create!(
  title: "Parkour Féminin - Lundi (19h00 - 20h30)",
  description: "#{course_description}\nCours féminin adultes, à partir de 16 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
  capacity: 30,
  weekday: :lundi,
  category: categories[:adults],
  features_attendance_sheet: true
)

courses[:teen_wednesday] = Course.create!(
  title: "Parkour Ados - Mercredi (14h15 - 15h30)",
  description: "#{course_description}\nCours pour les 10-15 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
  capacity: 30,
  weekday: :mercredi,
  category: categories[:teens],
  features_attendance_sheet: true
)

courses[:teen_saturday_early] = Course.create!(
  title: "Parkour Ados - Samedi A (14h15 - 15h30)",
  description: "#{course_description}\nCours pour les 10-15 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
  capacity: 30,
  weekday: :samedi,
  category: categories[:teens],
  features_attendance_sheet: true
)

courses[:teen_saturday_late] = Course.create!(
  title: "Parkour Ados - Samedi B (16h00 - 17h15)",
  description: "#{course_description}\nCours pour les 10-15 ans. Tarif annuel indicatif : 280€ pour un cours hebdomadaire.",
  capacity: 30,
  weekday: :samedi,
  category: categories[:teens],
  features_attendance_sheet: true
)

courses[:kidz] = Course.create!(
  title: "Parkour Kidz - Samedi (11h00 - 12h00)",
  description: "#{course_description}\nCours ludique pour les 6-9 ans, répartis en groupes 6/7 ans et 8/9 ans. Tarif annuel indicatif : 250€.",
  capacity: 20,
  weekday: :samedi,
  category: categories[:kids],
  features_attendance_sheet: true
)

courses[:health] = Course.create!(
  title: "Parkour Santé - Samedi (9h30 - 10h45)",
  description: "#{course_description}\nCours bienveillant pour reprendre confiance, mobilité et coordination, sans prérequis sportif.",
  capacity: 20,
  weekday: :samedi,
  category: categories[:health],
  features_attendance_sheet: true
)

courses.except(:health).each_value do |course|
  course.update!(discovery_enabled: true, discovery_price: 35, discovery_capacity: course.capacity)
end

## Discovery sessions

[
  {
    course: courses[:adult_monday],
    starts_at: Time.zone.local(2026, 8, 26, 19),
    capacity: 30,
    price: 35
  },
  {
    course: courses[:teen_wednesday],
    starts_at: Time.zone.local(2026, 8, 29, 14),
    capacity: 30,
    price: 35
  },
  {
    course: courses[:kidz],
    starts_at: Time.zone.local(2026, 8, 29, 11),
    capacity: 20,
    price: 35
  }
].each do |session|
  DiscoverySession.create!(
    course: session[:course],
    starts_at: session[:starts_at],
    capacity: session[:capacity],
    price: session[:price],
    active: true,
    open: true
  )
end

## Camps

platform.camps.create!(
  title: "Kidz Summer Camp (6 - 9 ans)",
  description: "Immersion de deux heures à Austerlitz autour de jeux, murets, barres et structures variées. Le stage développe coordination, maîtrise des mouvements et confiance dans un cadre adapté aux enfants.",
  capacity: 20,
  starts_at: Date.new(2026, 7, 11),
  ends_at: Date.new(2026, 7, 11),
  price: 60,
  external_price: 60,
  active: false,
  open: false,
  open_to_externals: true
)

platform.camps.create!(
  title: "Parkour Summer Camp (10 - 15 ans)",
  description: "Immersion de quatre jours sur le Quai Saint-Bernard à Austerlitz pour travailler précision, fluidité, enchaînements et contrôle du mouvement avec des coachs diplômés.",
  capacity: 30,
  starts_at: Date.new(2026, 7, 6),
  ends_at: Date.new(2026, 7, 10),
  price: 240,
  external_price: 240,
  active: false,
  open: false,
  open_to_externals: true
)
