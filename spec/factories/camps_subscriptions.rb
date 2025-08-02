FactoryBot.define do
  factory :camps_subscription do
    association :camp
    subscription do
      course = create(:course)
      member = create(:member)
      parent_subscription = create(:subscription, status: :confirmed, courses: [course], member:)
      build(:subscription, parent_subscription:, member:)
    end
  end
end
