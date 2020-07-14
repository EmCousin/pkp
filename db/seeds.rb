# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

## Default user

Subscription.destroy_all
Course.destroy_all
User.destroy_all

user = User.new
user.email = "monemail@mail.fr"
user.email_confirmation = "monemail@mail.fr"
user.first_name = "Maria"
user.last_name = "Silva"
user.admin = true
user.birthdate = 20.years.ago
user.phone_number = "+33299506779"
user.address = "1 rue des Halles"
user.zip_code = "75001"
user.city = "Paris"
user.country = "France"
user.agreed_to_publicity_right = true
user.avatar = Rack::Test::UploadedFile.new(Rails.root.join('public', 'pkp.jpg'), "image/jpeg")
user.contact_name = "Maria"
user.contact_phone_number = "+33299506779"
user.contact_relationship = User::CONTACTS.sample
user.password = "s3cr3tp4$$w0rd"

user.save!

## Default courses
Rake::Task["courses:seed"].invoke
