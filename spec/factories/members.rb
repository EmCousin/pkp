FactoryBot.define do
  factory :member do
    association :user, factory: :user
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { 20.years.ago }
    contact_name { Faker::Name.name }
    contact_phone_number { Faker::PhoneNumber.phone_number }
    contact_relationship { Member::CONTACTS.sample }
    agreed_to_advertising_right { true }
    avatar { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')) }
  end

  trait :minor do
    birthdate { 10.years.ago }
  end
end
