FactoryBot.define do
  factory :category do
    title { Faker::Lorem.word }
    min_age { 1 }
    max_age { 100 }
  end
end
