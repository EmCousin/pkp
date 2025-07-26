# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_24_130132) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "attendance_record_status", ["present", "absent", "excused"]
  create_enum "member_level", ["white", "yellow", "green", "red"]
  create_enum "payment_method", ["cash", "bank_transfer", "bank_check", "credit_card"]

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "attendance_sheet_id", null: false
    t.bigint "member_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "status", default: "present", null: false, enum_type: "attendance_record_status"
    t.index ["attendance_sheet_id", "member_id"], name: "index_attendance_records_on_attendance_sheet_id_and_member_id", unique: true
    t.index ["attendance_sheet_id"], name: "index_attendance_records_on_attendance_sheet_id"
    t.index ["member_id"], name: "index_attendance_records_on_member_id"
    t.index ["status"], name: "index_attendance_records_on_status"
  end

  create_table "attendance_sheets", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "date"], name: "index_attendance_sheets_on_course_id_and_date", unique: true
    t.index ["course_id"], name: "index_attendance_sheets_on_course_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "title", null: false
    t.integer "min_age", null: false
    t.integer "max_age", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_categories_on_title", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "email", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "title", null: false
    t.string "description"
    t.integer "capacity", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "weekday", null: false
    t.boolean "active", default: true
    t.bigint "category_id"
    t.boolean "features_attendance_sheet", default: false, null: false
    t.index ["category_id"], name: "index_courses_on_category_id"
  end

  create_table "courses_subscriptions", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "subscription_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id"], name: "index_courses_subscriptions_on_course_id"
    t.index ["subscription_id"], name: "index_courses_subscriptions_on_subscription_id"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "user_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birthdate", null: false
    t.string "contact_name", null: false
    t.string "contact_phone_number", null: false
    t.string "contact_relationship", null: false
    t.boolean "agreed_to_advertising_right", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "level", default: "white", null: false, enum_type: "member_level"
    t.index ["first_name", "last_name"], name: "index_members_on_first_name_and_last_name"
    t.index ["level"], name: "index_members_on_level"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "year", null: false
    t.decimal "fee", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status", default: 0
    t.string "stripe_charge_id"
    t.bigint "member_id"
    t.datetime "terms_accepted_at"
    t.datetime "doctor_certified_at"
    t.datetime "paid_at"
    t.enum "payment_method", enum_type: "payment_method"
    t.index ["created_at"], name: "index_subscriptions_on_created_at", order: :desc
    t.index ["member_id"], name: "index_subscriptions_on_member_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["year"], name: "index_subscriptions_on_year"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "phone_number"
    t.string "address"
    t.string "zip_code"
    t.string "city"
    t.string "country"
    t.string "stripe_customer_id"
    t.boolean "terms_of_service", default: false
    t.boolean "coach", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendance_records", "attendance_sheets"
  add_foreign_key "attendance_records", "members"
  add_foreign_key "attendance_sheets", "courses"
  add_foreign_key "contacts", "users"
  add_foreign_key "courses", "categories"
  add_foreign_key "courses_subscriptions", "courses"
  add_foreign_key "courses_subscriptions", "subscriptions"
  add_foreign_key "members", "users"
  add_foreign_key "subscriptions", "members"
end
