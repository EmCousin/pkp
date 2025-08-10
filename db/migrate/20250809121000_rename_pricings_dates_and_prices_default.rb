# frozen_string_literal: true

class RenamePricingsDatesAndPricesDefault < ActiveRecord::Migration[8.0]
  def up
    # Fix index referencing old columns if present
    if index_exists?(:pricings, %i[category_id starts_on ends_on], name: 'index_pricings_on_category_id_and_starts_on_and_ends_on')
      remove_index :pricings, name: 'index_pricings_on_category_id_and_starts_on_and_ends_on'
    end

    # Drop old check constraint if present
    execute <<~SQL
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'pricings_starts_on_before_or_equal_ends_on'
        ) THEN
          ALTER TABLE pricings DROP CONSTRAINT pricings_starts_on_before_or_equal_ends_on;
        END IF;
      END$$;
    SQL

    # Rename columns
    if column_exists?(:pricings, :starts_on)
      rename_column :pricings, :starts_on, :starts_at
    end
    if column_exists?(:pricings, :ends_on)
      rename_column :pricings, :ends_on, :ends_at
    end

    # Add new index on period
    add_index :pricings, %i[category_id starts_at ends_at], name: 'index_pricings_on_category_and_period'

    # Add new check constraint
    execute <<~SQL
      ALTER TABLE pricings
      ADD CONSTRAINT pricings_starts_at_before_or_equal_ends_at
      CHECK (starts_at <= ends_at);
    SQL

    # Ensure prices default is an array and fix existing records
    change_column_default :pricings, :prices, from: {}, to: []
    execute <<~SQL
      UPDATE pricings SET prices = '[]'::jsonb
      WHERE jsonb_typeof(prices) IS DISTINCT FROM 'array';
    SQL
  end

  def down
    # Revert prices default
    change_column_default :pricings, :prices, from: [], to: {}

    # Drop new check constraint
    execute <<~SQL
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'pricings_starts_at_before_or_equal_ends_at'
        ) THEN
          ALTER TABLE pricings DROP CONSTRAINT pricings_starts_at_before_or_equal_ends_at;
        END IF;
      END$$;
    SQL

    # Remove new index
    remove_index :pricings, name: 'index_pricings_on_category_and_period' if index_exists?(:pricings, name: 'index_pricings_on_category_and_period')

    # Rename columns back
    if column_exists?(:pricings, :starts_at)
      rename_column :pricings, :starts_at, :starts_on
    end
    if column_exists?(:pricings, :ends_at)
      rename_column :pricings, :ends_at, :ends_on
    end

    # Recreate old index
    add_index :pricings, %i[category_id starts_on ends_on], name: 'index_pricings_on_category_id_and_starts_on_and_ends_on'

    # Recreate old check constraint
    execute <<~SQL
      ALTER TABLE pricings
      ADD CONSTRAINT pricings_starts_on_before_or_equal_ends_on
      CHECK (starts_on <= ends_on);
    SQL
  end
end


