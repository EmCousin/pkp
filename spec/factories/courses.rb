FactoryBot.define do
  factory :course do
    association :category
    title { Faker::Lorem.word.presence || 'Default Course Title' }
    description { Faker::Lorem.paragraph }
    weekday { Course.weekdays.keys.sample }

    trait :with_capacity do
      after(:create) do |course|
        course.capacities_courses.update_all(capacity: 15)
      end
    end
  end
end
