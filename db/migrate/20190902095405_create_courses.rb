class CreateCourses < ActiveRecord::Migration[5.1]
  def change
    create_table :courses do |t|
      t.string :title,  null: false
      t.string :description
      t.integer :capacity,  null: false
      t.string :category,  null: false

      t.timestamps
    end
  end
end
