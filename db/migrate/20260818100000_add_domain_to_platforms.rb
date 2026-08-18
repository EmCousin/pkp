# frozen_string_literal: true

class AddDomainToPlatforms < ActiveRecord::Migration[8.1]
  def up
    add_column :platforms, :domain, :string
    backfill_domains
    change_column_null :platforms, :domain, false
    add_index :platforms, :domain, unique: true
  end

  def down
    remove_column :platforms, :domain
  end

  private

  def backfill_domains
    execute <<~SQL.squish
      UPDATE platforms
      SET domain = CASE
        WHEN name = 'Parkour Paris' THEN 'parkourparis.fr'
        ELSE CONCAT('platform-', id, '.invalid')
      END
    SQL
  end
end
