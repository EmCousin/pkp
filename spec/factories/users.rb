FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'surprise' }
    phone_number { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    zip_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    country { Faker::Address.country }

    trait :admin do
      admin { true }
    end
  end
end
