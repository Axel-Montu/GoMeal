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

ActiveRecord::Schema[8.1].define(version: 2026_09_01_104141) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "go_meal_matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "go_meal_score"
    t.bigint "restaurant_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "visited", default: false
    t.index ["restaurant_id"], name: "index_go_meal_matches_on_restaurant_id"
    t.index ["user_id"], name: "index_go_meal_matches_on_user_id"
  end

  create_table "price_ranges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "end_price"
    t.bigint "restaurant_id", null: false
    t.string "start_price"
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_price_ranges_on_restaurant_id"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.text "editorial_summary"
    t.float "google_rating"
    t.float "latitude"
    t.float "longitude"
    t.string "name"
    t.string "types", default: [], array: true
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "api_type"
    t.string "backend_tag"
    t.datetime "created_at", null: false
    t.string "frontend_tag"
    t.string "frontend_type"
    t.datetime "updated_at", null: false
  end

  create_table "user_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tag_id"], name: "index_user_tags_on_tag_id"
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "average_lunch_time_minutes"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "max_walking_minutes"
    t.string "preferred_start_address"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "go_meal_matches", "restaurants"
  add_foreign_key "go_meal_matches", "users"
  add_foreign_key "price_ranges", "restaurants"
  add_foreign_key "user_tags", "tags"
  add_foreign_key "user_tags", "users"
end
