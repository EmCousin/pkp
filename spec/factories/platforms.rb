FactoryBot.define do
  factory :platform do
    sequence(:name) { |number| "Platform #{number}" }
    medical_certificate_validity_seasons { 3 }
  end
end
