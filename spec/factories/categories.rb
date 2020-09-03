FactoryBot.define do
  factory :category do
    title { 'Adulte' }
    min_age { 1 }
    max_age { 100 }
  end
end
