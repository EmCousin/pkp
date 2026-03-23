FactoryBot.define do
  factory :course do
    association :category
    title { Faker::Lorem.word.presence || 'Default Course Title' }
    description { Faker::Lorem.paragraph }
    weekday { Course.weekdays.keys.sample }

    after(:create) do |course|
      Member.levels.keys.each do |level|
        create(:capacities_course, course: course, level: level, capacity: 15)
      end
    end
  end
end
