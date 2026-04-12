FactoryBot.define do
  factory :capacities_course do
    association :course
    level { Member.levels.keys.sample }
    capacity { 15 }
  end
end
