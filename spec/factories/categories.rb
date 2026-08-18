FactoryBot.define do
  factory :category do
    platform do
      Platform.find_or_create_by!(domain: 'example.com') do |platform|
        platform.name = 'Parkour Paris'
      end
    end
    title { 'Adulte' }
    min_age { 1 }
    max_age { 100 }

    trait :kidz do
      title { 'Kidz (6 - 7 ans)' }
      min_age { 6 }
      max_age { 9 }
    end
  end
end
