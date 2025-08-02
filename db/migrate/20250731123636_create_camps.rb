class CreateCamps < ActiveRecord::Migration[8.0]
  def change
    create_table :camps do |t|
      t.string :title
      t.integer :capacity
      t.date :starts_at
      t.date :ends_at
      t.decimal :price
      t.boolean :active

      t.timestamps
    end
  end
end
