FactoryBot.define do
  factory :category do
    title { 'Adulte' }
    min_age { 1 }
    max_age { 100 }

    trait :kidz do
      min_age { 6 }
      max_age { 9 }
    end
  end
end
