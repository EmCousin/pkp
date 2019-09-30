class CreateCoursesSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :courses_subscriptions do |t|
      t.references :course, foreign_key: true
      t.references :subscription, foreign_key: true

      t.timestamps
    end
  end
end
