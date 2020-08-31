FactoryBot.define do
  factory :course do
    association :category
    title { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    capacity { 60 }
    weekday { Course.weekdays.keys.sample }
  end
end
