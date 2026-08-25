# frozen_string_literal: true

class AddAuthenticationGeneration < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :authentication_generation, :bigint, default: 0, null: false
    add_column :auth_sessions, :authentication_generation, :bigint, default: 0, null: false
    create_authentication_generation_trigger
  end

  def down
    execute 'DROP TRIGGER IF EXISTS advance_authentication_generation ON users'
    execute 'DROP FUNCTION IF EXISTS advance_authentication_generation()'
    remove_column :auth_sessions, :authentication_generation
    remove_column :users, :authentication_generation
  end

  private

  def create_authentication_generation_trigger
    execute <<~SQL
      CREATE FUNCTION advance_authentication_generation()
      RETURNS trigger AS $$
      BEGIN
        IF (
          NEW.encrypted_password IS DISTINCT FROM OLD.encrypted_password
          OR (OLD.locked_at IS NULL AND NEW.locked_at IS NOT NULL)
        ) AND NEW.authentication_generation = OLD.authentication_generation THEN
          NEW.authentication_generation = OLD.authentication_generation + 1;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER advance_authentication_generation
      BEFORE UPDATE OF encrypted_password, locked_at ON users
      FOR EACH ROW EXECUTE FUNCTION advance_authentication_generation();
    SQL
  end
end
