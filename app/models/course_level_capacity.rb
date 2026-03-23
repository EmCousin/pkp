# frozen_string_literal: true

class CourseLevelCapacity < ApplicationRecord
  belongs_to :course

  validates :level, presence: true, inclusion: { in: Member.levels.keys }
  validates :capacity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :level, uniqueness: { scope: :course_id }

  enum :level, Member.levels
end
