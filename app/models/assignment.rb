# frozen_string_literal: true

class Assignment < ApplicationRecord
  belongs_to :course
  belongs_to :coach, -> { where(coach: true) }, class_name: 'Member', inverse_of: :assignments

  enum :level, white: 'white', yellow: 'yellow', green: 'green', red: 'red'

  validates :level, :year, presence: true
  validates :year, numericality: { only_integer: true }
  validates :coach_id, uniqueness: { scope: %i[course_id level year] }
end
