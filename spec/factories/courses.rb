FactoryBot.define do
  factory :course do
    association :category
    title { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    capacity { 60 }
    weekday { Course.weekdays.keys.sample }

    trait :discoverable do
      discovery_enabled { true }
      discovery_price { 25 }
      discovery_capacity { 12 }
    end
  end
end
