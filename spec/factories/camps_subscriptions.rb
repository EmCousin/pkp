FactoryBot.define do
  factory :camps_subscription do
    association :camp
    subscription do
      course = create(:course)
      member = create(:member)
      parent_subscription = create(:subscription, status: :confirmed, courses: [course], member:, year: camp.year)
      build(:subscription, registration_type: :camp, parent_subscription:, member:, year: camp.year)
    end
  end
end
