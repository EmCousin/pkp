# frozen_string_literal: true

class CreateCourseUnavailabilityPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :course_unavailability_periods do |t|
      t.references :platform, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false

      t.timestamps
    end

    add_index :course_unavailability_periods, %i[platform_id starts_on ends_on],
              name: :index_course_unavailability_periods_on_platform_and_dates
    add_check_constraint :course_unavailability_periods, 'starts_on <= ends_on',
                         name: :course_unavailability_periods_valid_dates

    create_table :course_unavailabilities do |t|
      t.references :course_unavailability_period, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end

    add_index :course_unavailabilities,
              %i[course_unavailability_period_id course_id],
              unique: true,
              name: :index_course_unavailabilities_on_period_and_course
  end
end
