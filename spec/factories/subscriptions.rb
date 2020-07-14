FactoryBot.define do
  factory :subscription do
    association :member, factory: :user
    year { Time.current.year }
    fee { 0 }
  end
end
