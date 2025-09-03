FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'surprise' }
    phone_number { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    zip_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    country { Faker::Address.country }
    terms_of_service { true }
    stripe_customer_id { Faker::Internet.uuid }

    trait :admin do
      admin { true }
    end
  end
end
