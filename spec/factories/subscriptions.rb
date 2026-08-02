FactoryBot.define do
  factory :subscription, class: 'AnnualSubscription' do
    association :member, factory: :member
    year { discovery_session&.year || Subscription.current_year }
    status { :pending }
  end

  factory :camp_registration, class: 'CampRegistration', parent: :subscription
  factory :discovery_registration, class: 'DiscoveryRegistration', parent: :subscription
end
