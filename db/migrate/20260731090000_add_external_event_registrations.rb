class AddExternalEventRegistrations < ActiveRecord::Migration[8.0]
  def up
    validate_existing_data!

    remove_index :subscriptions, name: "index_subscriptions_on_member_id_and_year", if_exists: true

    add_column :camps, :external_price, :decimal
    add_column :camps, :open_to_externals, :boolean, default: false, null: false

    execute "UPDATE camps SET external_price = price"
    execute <<~SQL
      CREATE FUNCTION populate_camp_external_price() RETURNS trigger AS $$
      BEGIN
        IF NEW.external_price IS NULL THEN
          NEW.external_price := NEW.price;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    execute <<~SQL
      CREATE TRIGGER populate_camp_external_price_before_write
      BEFORE INSERT OR UPDATE ON camps
      FOR EACH ROW EXECUTE FUNCTION populate_camp_external_price();
    SQL
    change_column_null :camps, :external_price, false

    create_table :discovery_sessions do |t|
      t.references :course, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer :capacity, null: false
      t.decimal :price, null: false
      t.boolean :active, default: false, null: false
      t.boolean :open, default: false, null: false

      t.timestamps
    end
    add_index :discovery_sessions, :starts_at

    add_column :subscriptions, :registration_type, :integer, default: 0, null: false
    add_reference :subscriptions, :discovery_session, foreign_key: true
    add_column :subscriptions, :attendance_status, :enum, enum_type: "attendance_record_status"

    execute <<~SQL.squish
      UPDATE subscriptions
      SET registration_type = 1
      WHERE id IN (SELECT subscription_id FROM camps_subscriptions)
    SQL
    execute <<~SQL
      CREATE FUNCTION mark_camp_registration() RETURNS trigger AS $$
      BEGIN
        UPDATE subscriptions SET registration_type = 1 WHERE id = NEW.subscription_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    execute <<~SQL
      CREATE TRIGGER mark_camp_registration_after_write
      AFTER INSERT OR UPDATE OF subscription_id ON camps_subscriptions
      FOR EACH ROW EXECUTE FUNCTION mark_camp_registration();
    SQL

    add_index :subscriptions,
              %i[member_id year],
              unique: true,
              where: "registration_type = 0 AND parent_subscription_id IS NULL",
              name: "index_one_annual_subscription_per_member_and_year"
    add_index :subscriptions,
              %i[discovery_session_id member_id],
              unique: true,
              where: "discovery_session_id IS NOT NULL",
              name: "index_one_subscription_per_discovery_session_and_member"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Event registrations cannot be converted back to annual subscriptions safely"
  end

  private

  def validate_existing_data!
    if select_value("SELECT 1 FROM camps WHERE price IS NULL LIMIT 1")
      raise ActiveRecord::MigrationError, "All existing camps need a price before adding external registrations"
    end

    duplicate = select_value(<<~SQL.squish)
      SELECT 1
      FROM subscriptions
      WHERE member_id IS NOT NULL AND parent_subscription_id IS NULL
      GROUP BY member_id, year
      HAVING COUNT(*) > 1
      LIMIT 1
    SQL
    return unless duplicate

    raise ActiveRecord::MigrationError, "Duplicate annual subscriptions must be resolved before adding the unique index"
  end
end
