# frozen_string_literal: true

class CreateCourseLevelCapacities < ActiveRecord::Migration[8.0]
  def change
    create_table :course_level_capacities do |t|
      t.references :course, null: false, foreign_key: true
      t.enum :level, null: false, enum_type: 'member_level'
      t.integer :capacity, null: false, default: 0

      t.timestamps
    end

    add_index :course_level_capacities, %i[course_id level], unique: true
  end
end
