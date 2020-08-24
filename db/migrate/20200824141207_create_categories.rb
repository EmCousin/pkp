class CreateCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :categories do |t|
      t.string :title
      t.integer :min_age
      t.integer :max_age

      t.timestamps
    end

    execute(
      <<-SQL
        INSERT INTO categories (title, min_age, max_age, created_at, updated_at)
        VALUES
        ('Adulte', null, null, NOW(), NOW()),
        ('Adolescent (10 - 12 ans)', 10, 12, NOW(), NOW()),
        ('Adolescent (13 - 15 ans)', 13, 15, NOW(), NOW()),
        ('Kidz (6 - 7 ans)', 6, 7, NOW(), NOW()),
        ('Kidz (8 - 9 ans)', 8, 9, NOW(), NOW());
      SQL
    )

    add_reference :courses, :category, foreign_key: true

    execute(
      <<-SQL
        UPDATE courses
        SET category_id = categories.id
        FROM categories
        WHERE courses.category = categories.title;
      SQL
    )

    remove_column :courses, :category, :string, null: false
  end
end
