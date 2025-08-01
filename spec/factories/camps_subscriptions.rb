FactoryBot.define do
  factory :camps_subscription do
    association :camp
    association :subscription
  end
end
