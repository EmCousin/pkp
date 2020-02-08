FactoryBot.define do
  factory :user do
    avatar { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'file_examples', 'example.svg')) }
    email { Faker::Internet.email }
    password { 'surprise' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { 20.year.ago }
    phone_number { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    zip_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    country { Faker::Address.country }
    contact_name { Faker::Name.name }
    contact_phone_number { Faker::PhoneNumber.phone_number }
    contact_relationship { User::CONTACTS.sample }
    agreed_to_publicity_right { true }

    trait :admin do
      admin { true }
    end
  end
end
