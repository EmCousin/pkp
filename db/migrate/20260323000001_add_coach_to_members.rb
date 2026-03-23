# frozen_string_literal: true

class AddCoachToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :coach, :boolean, default: false, null: false
  end
end
