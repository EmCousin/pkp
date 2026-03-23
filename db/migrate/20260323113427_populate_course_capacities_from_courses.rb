# frozen_string_literal: true

class PopulateCourseCapacitiesFromCourses < ActiveRecord::Migration[8.0]
  def up
    Course.find_each do |course|
      levels = Member.levels.keys

      # If course capacity is too small, don't create level capacities
      # (let it use the default global capacity behavior)
      next if course.capacity < levels.size

      base_capacity = course.capacity / levels.size
      remainder = course.capacity % levels.size

      levels.each_with_index do |level, index|
        # Distribute remainder to first levels
        level_capacity = base_capacity + (index < remainder ? 1 : 0)

        CourseCapacity.create!(
          course: course,
          level: level,
          capacity: level_capacity
        )
      end
    end
  end

  def down
    CourseCapacity.delete_all
  end
end
