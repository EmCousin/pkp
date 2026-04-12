# frozen_string_literal: true

class PopulateCourseCapacitiesFromCourses < ActiveRecord::Migration[8.0]
  class Course < ApplicationRecord
    has_many :capacities_courses, class_name: 'PopulateCourseCapacitiesFromCourses::CapacitiesCourse'
  end

  class CapacitiesCourse < ApplicationRecord
    belongs_to :course, class_name: 'PopulateCourseCapacitiesFromCourses::Course'
  end

  def up
    levels = %w[white yellow green red]
    records = []

    Course.find_each do |course|
      # If course capacity is too small, don't create level capacities
      # (let it use the default global capacity behavior)
      next if course.capacity < levels.size

      base_capacity = course.capacity / levels.size
      remainder = course.capacity % levels.size

      levels.each_with_index do |level, index|
        # Distribute remainder to first levels
        level_capacity = base_capacity + (index < remainder ? 1 : 0)

        records << {
          course_id: course.id,
          level: level,
          capacity: level_capacity,
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    CapacitiesCourse.insert_all(records) if records.any?
  end

  def down
    CapacitiesCourse.delete_all
  end
end
