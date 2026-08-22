FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'surprise' }
    sequence(:phone_number) { |n| format('+336%08d', n) }
    address { Faker::Address.street_address }
    zip_code { Faker::Address.zip_code }
    city { Faker::Address.city }
    country { 'FR' }
    terms_of_service { true }
    stripe_customer_id { Faker::Internet.uuid }

    trait :admin do
      admin { true }
    end
  end
end
