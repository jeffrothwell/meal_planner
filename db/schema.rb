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

ActiveRecord::Schema[8.1].define(version: 2026_05_26_134856) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "meal_plan_meals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "meal_id", null: false
    t.bigint "meal_plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_id", "meal_plan_id"], name: "index_meal_plan_meals_on_meal_id_and_meal_plan_id", unique: true
    t.index ["meal_id"], name: "index_meal_plan_meals_on_meal_id"
    t.index ["meal_plan_id"], name: "index_meal_plan_meals_on_meal_plan_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "meal_count", default: 6, null: false
    t.datetime "updated_at", null: false
    t.date "week_start_date", null: false
    t.index ["week_start_date"], name: "index_meal_plans_on_week_start_date", unique: true
  end

  create_table "meals", force: :cascade do |t|
    t.integer "adult_rating", limit: 2
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.integer "dinner_count", default: 1, null: false
    t.integer "kids_rating", limit: 2
    t.integer "nutrition_rating", limit: 2
    t.string "recipe_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_meals_on_title", unique: true
  end

  add_foreign_key "meal_plan_meals", "meal_plans"
  add_foreign_key "meal_plan_meals", "meals"
end
