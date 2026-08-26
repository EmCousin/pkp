# frozen_string_literal: true

class ReplaceDeviseWithAuthentication < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :encrypted_password, :password_digest
    create_auth_sessions
    remove_unused_devise_columns
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Devise authentication tokens and confirmation data were discarded'
  end

  private

  def create_auth_sessions
    create_table :auth_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_seen_at, null: false
      t.datetime :remembered_until
      t.timestamps

      t.index :last_seen_at
      t.index :remembered_until
    end
  end

  def remove_unused_devise_columns
    remove_index :users, :confirmation_token, unique: true
    remove_column :users, :confirmation_token, :string
    remove_column :users, :confirmed_at, :datetime
    remove_column :users, :confirmation_sent_at, :datetime
    remove_column :users, :unconfirmed_email, :string
    remove_column :users, :remember_created_at, :datetime
    remove_index :users, :reset_password_token, unique: true
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_index :users, :unlock_token, unique: true
    remove_column :users, :unlock_token, :string
  end
end
