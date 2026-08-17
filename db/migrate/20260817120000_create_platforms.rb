# frozen_string_literal: true

class CreatePlatforms < ActiveRecord::Migration[8.1]
  def up
    create_table :platforms do |t|
      t.string :name, null: false
      t.integer :medical_certificate_validity_seasons, null: false, default: 3

      t.timestamps
    end
    add_index :platforms, :name, unique: true
    add_check_constraint :platforms,
                         'medical_certificate_validity_seasons > 0',
                         name: 'platforms_medical_certificate_validity_seasons_positive'

    execute <<~SQL.squish
      INSERT INTO platforms (name, medical_certificate_validity_seasons, created_at, updated_at)
      VALUES ('Parkour Paris', 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL

    %i[members categories camps].each do |table|
      add_reference table, :platform, foreign_key: true
      execute <<~SQL.squish
        UPDATE #{table}
        SET platform_id = (SELECT id FROM platforms WHERE name = 'Parkour Paris')
        WHERE platform_id IS NULL
      SQL
      change_column_null table, :platform_id, false
    end

  end

  def down
    %i[members categories camps].each do |table|
      remove_reference table, :platform, foreign_key: true
    end

    drop_table :platforms
  end
end
