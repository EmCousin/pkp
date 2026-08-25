# frozen_string_literal: true

class AddAuthenticationGeneration < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :authentication_generation, :bigint, default: 0, null: false
    add_column :auth_sessions, :authentication_generation, :bigint, default: 0, null: false
  end
end
