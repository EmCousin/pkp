# frozen_string_literal: true

FactoryBot.define do
  factory :pricing do
    association :category
    name { 'Default' }
    starts_at { Date.today }
    ends_at { Date.today + 30 }
    prices { [240, 360] }
  end
end


