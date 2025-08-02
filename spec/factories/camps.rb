FactoryBot.define do
  factory :camp do
    sequence(:title) { |n| "Stage #{n}" }
    description { "Description du stage" }
    capacity { 20 }
    starts_at { 1.month.from_now }
    ends_at { 1.month.from_now + 5.days }
    price { 150.0 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :fully_booked do
      capacity { 1 }
      after(:create) do |camp|
        create(:camps_subscription, camp: camp)
      end
    end

    trait :with_cover_picture do
      after(:build) do |camp|
        camp.cover_picture.attach(
          io: File.open(Rails.root.join('spec', 'support', 'file_examples', 'avatar.jpg')),
          filename: 'camp_cover.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end
