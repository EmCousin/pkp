# frozen_string_literal: true

FactoryBot.define do
  factory :assignment do
    association :coach, factory: %i[member coach]
    association :course
    level { :white }
    year { Time.current.year }
  end
end
