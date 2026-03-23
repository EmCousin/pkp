# frozen_string_literal: true

class AddCoachToMembers < ActiveRecord::Migration[7.2]
  def change
    add_column :members, :coach, :boolean, default: false, null: false
  end
end
