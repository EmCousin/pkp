FactoryBot.define do
  factory :course do
    title { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    capacity { 60 }
    category { Course::CATEGORIES.sample }
    weekday { Course.weekdays.keys.sample }
  end
end
