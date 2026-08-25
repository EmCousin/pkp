# frozen_string_literal: true

class ReplaceDeviseWithAuthentication < ActiveRecord::Migration[8.1]
  def change
    create_auth_sessions
  end

  private

  def create_auth_sessions
    create_table :auth_sessions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :credential_fingerprint, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_seen_at, null: false
      t.datetime :remembered_until
      t.timestamps

      t.index :last_seen_at
      t.index :remembered_until
    end
  end
end
