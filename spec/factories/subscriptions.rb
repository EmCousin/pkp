FactoryBot.define do
  factory :subscription do
    association :member, factory: :member
  end
end
