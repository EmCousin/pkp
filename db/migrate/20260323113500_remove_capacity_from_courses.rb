# frozen_string_literal: true

class RemoveCapacityFromCourses < ActiveRecord::Migration[8.0]
  class Course < ApplicationRecord
    has_many :capacities_courses, class_name: 'RemoveCapacityFromCourses::CapacitiesCourse'
  end

  class CapacitiesCourse < ApplicationRecord
    belongs_to :course, class_name: 'RemoveCapacityFromCourses::Course'
  end

  def up
    remove_column :courses, :capacity
  end

  def down
    add_column :courses, :capacity, :integer

    Course.find_each do |course|
      total_capacity = course.capacities_courses.sum(:capacity)
      course.update_column(:capacity, total_capacity.positive? ? total_capacity : 1)
    end

    change_column_null :courses, :capacity, false
  end
end
