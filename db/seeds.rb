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
Member.destroy_all
User.destroy_all

user = User.new
user.email = "monemail@mail.fr"
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
# Rake::Task["courses:seed"].invoke
