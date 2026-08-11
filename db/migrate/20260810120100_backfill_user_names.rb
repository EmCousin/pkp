# frozen_string_literal: true

class BackfillUserNames < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    loop do
      result = execute <<~SQL.squish
        WITH batch AS (
          SELECT id FROM users
          WHERE first_name IS NULL OR last_name IS NULL
          ORDER BY id
          LIMIT 1000
        )
        UPDATE users
        SET first_name = COALESCE(
              users.first_name,
              (SELECT members.first_name FROM members WHERE members.user_id = users.id ORDER BY members.created_at LIMIT 1),
              'Compte'
            ),
            last_name = COALESCE(
              users.last_name,
              (SELECT members.last_name FROM members WHERE members.user_id = users.id ORDER BY members.created_at LIMIT 1),
              'A completer'
            )
        FROM batch
        WHERE users.id = batch.id
        RETURNING users.id
      SQL
      break if result.ntuples.zero?

      sleep 0.01
    end
  end

  def down; end
end
