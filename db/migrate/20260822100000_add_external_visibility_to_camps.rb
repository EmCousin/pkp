# frozen_string_literal: true

class AddExternalVisibilityToCamps < ActiveRecord::Migration[8.1]
  def up
    add_column :camps, :visible_to_externals, :boolean, default: false, null: false

    execute <<~SQL.squish
      UPDATE camps
      SET visible_to_externals = COALESCE(active, FALSE)
    SQL
  end

  def down
    remove_column :camps, :visible_to_externals
  end
end
