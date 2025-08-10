# frozen_string_literal: true

class CreatePricings < ActiveRecord::Migration[8.0]
  def change
    create_table :pricings do |t|
      t.references :category, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.jsonb :prices, null: false, default: []
      t.date :starts_at, null: false
      t.date :ends_at, null: false

      t.timestamps
    end

    add_index :pricings, [:category_id, :starts_at, :ends_at], name: 'index_pricings_on_category_and_period'
  end
end

# frozen_string_literal: true

class CreatePricings < ActiveRecord::Migration[7.1]
  def change
    create_table :pricings do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :prices, null: false, default: {}
      t.date :starts_on, null: false
      t.date :ends_on, null: false

      t.timestamps
      t.index [:category_id, :starts_on, :ends_on]
      t.check_constraint 'starts_on <= ends_on', name: 'pricings_starts_on_before_or_equal_ends_on'
    end
  end
end
