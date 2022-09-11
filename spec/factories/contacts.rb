FactoryBot.define do
  factory :contact do
    association :user
    email { Faker::Internet.email }
    confirmed_at { Time.current }
  end
end
