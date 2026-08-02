class AddRecurringDiscoverySettings < ActiveRecord::Migration[8.1]
  def change
    add_column :courses, :discovery_enabled, :boolean, default: false, null: false
    add_column :courses, :discovery_price, :decimal
    add_column :courses, :discovery_capacity, :integer

    add_column :discovery_sessions, :occurs_on, :date
    add_index :discovery_sessions,
              %i[course_id occurs_on],
              unique: true,
              where: "occurs_on IS NOT NULL",
              name: "index_one_discovery_session_per_course_and_date"
  end
end
