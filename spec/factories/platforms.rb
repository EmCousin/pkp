FactoryBot.define do
  factory :platform do
    sequence(:name) { |number| "Platform #{number}" }
    sequence(:domain) { |number| "platform-#{number}.test" }
    medical_certificate_validity_seasons { 3 }
  end
end
