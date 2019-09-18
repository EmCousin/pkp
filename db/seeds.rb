# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

user = User.new
user.email = "monemail@mail.fr"
user.first_name = "Maria"
user.last_name = "Silva"
user.admin = true
user.birthdate = 20.years.from_now
user.phone_number = "0123456987"
user.address = "1 rue des Halles"
user.zip_code = "75001"
user.city = "Paris"
user.country = "France"
user.agreed_to_publicity_right = true
user.avatar = Rack::Test::UploadedFile.new(Rails.root.join('public', 'pkp.jpg'), "image/jpeg")
user.contact_name = "Maria"
user.contact_phone_number = "0123456987"
user.contact_relationship = User::CONTACTS.sample
user.password = "coucou"
user.save!
