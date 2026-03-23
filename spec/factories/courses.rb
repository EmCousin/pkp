FactoryBot.define do
  factory :course do
    association :category
    title { Faker::Lorem.word.presence || 'Default Course Title' }
    description { Faker::Lorem.paragraph }
    weekday { Course.weekdays.keys.sample }
  end
end
