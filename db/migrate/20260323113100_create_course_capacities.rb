# frozen_string_literal: true

class CreateCourseCapacities < ActiveRecord::Migration[8.0]
  def change
    create_table :capacities_courses do |t|
      t.references :course, null: false, foreign_key: true
      t.enum :level, null: false, enum_type: :member_level
      t.integer :capacity, null: false, default: 0
      t.timestamps
      t.index [:course_id, :level], unique: true
    end
  end
end
