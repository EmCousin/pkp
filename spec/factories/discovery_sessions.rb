FactoryBot.define do
  factory :discovery_session do
    association :course
    starts_at { 1.week.from_now }
    capacity { 12 }
    price { 25 }
    active { true }
    open { true }
  end
end
