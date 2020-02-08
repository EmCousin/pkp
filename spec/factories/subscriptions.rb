FactoryBot.define do
  factory :subscription do
    association :member, factory: :user
    year { Time.now.year }
    fee { 0 }
  end
end
