# frozen_string_literal: true

class CourseCapacity < ApplicationRecord
  belongs_to :course

  enum :level, Member.levels, prefix: true

  validates :level, presence: true, uniqueness: { scope: :course_id }
  validates :capacity, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
