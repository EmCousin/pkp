# frozen_string_literal: true

class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :coach, null: false, foreign_key: { to_table: :members }
      t.references :course, null: false, foreign_key: true
      t.enum :level, enum_type: :member_level, null: false
      t.integer :year, null: false
      t.timestamps
    end

    add_index :assignments, %i[coach_id course_id level year], unique: true
  end
end
