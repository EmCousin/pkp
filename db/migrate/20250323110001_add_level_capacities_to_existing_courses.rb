# frozen_string_literal: true

class AddLevelCapacitiesToExistingCourses < ActiveRecord::Migration[8.0]
  def up
    Course.find_each do |course|
      Member.levels.keys.each do |level|
        CourseLevelCapacity.find_or_create_by!(course: course, level: level) do |clc|
          clc.capacity = 0 # Default to 0, meaning no specific limit
        end
      end
    end
  end

  def down
    # Data migration rollback is a no-op as we keep the data
  end
end
