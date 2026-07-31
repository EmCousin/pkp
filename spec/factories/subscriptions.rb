FactoryBot.define do
  factory :subscription do
    association :member, factory: :member
    year { discovery_session&.year || Subscription.current_year }
    status { :pending }
  end
end
