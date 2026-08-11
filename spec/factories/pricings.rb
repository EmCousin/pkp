# frozen_string_literal: true

FactoryBot.define do
  factory :pricing do
    association :category
    name { 'Default' }
    starts_at { Date.current }
    ends_at { Date.current + 30 }
    prices { [240, 360] }
  end
end

