class AddLevelToMembers < ActiveRecord::Migration[7.0]
  def change
    create_enum "member_level", ["white", "yellow", "green", "red"]

    reversible do |dir|
      dir.down do
        execute("DROP TYPE member_level")
      end
    end

    add_column :members, :level, :enum, default: "white", null: false, enum_type: "member_level"
    add_index :members, :level
  end
end
