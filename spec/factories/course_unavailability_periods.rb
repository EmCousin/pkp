# frozen_string_literal: true

FactoryBot.define do
  factory :course_unavailability_period do
    platform { association(:platform) }
    starts_on { Date.current }
    ends_on { starts_on + 1.week }
  end
end
