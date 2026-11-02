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

ActiveRecord::Schema[8.1].define(version: 2026_11_02_000000) do
  create_table "aquarium_species", force: :cascade do |t|
    t.integer "aquarium_id"
    t.integer "species_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "count"
    t.index ["aquarium_id"], name: "index_aquarium_species_on_aquarium_id"
    t.index ["species_id"], name: "index_aquarium_species_on_species_id"
  end

  create_table "aquariums", force: :cascade do |t|
    t.decimal "size", precision: 8, scale: 2
    t.string "water_type"
    t.string "filter"
    t.boolean "plants"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "substrate"
    t.boolean "public", default: true, null: false
  end

  create_table "species", force: :cascade do |t|
    t.string "common_name"
    t.string "taxonomic_name"
    t.string "image_url"
    t.string "size"
    t.string "other_remarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preferred_water"
    t.string "category", default: "fish", null: false
    t.index ["category"], name: "index_species_on_category"
  end

  create_table "species_aliases", force: :cascade do |t|
    t.integer "species_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_species_aliases_on_name"
    t.index ["species_id"], name: "index_species_aliases_on_species_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "per_page", default: 25, null: false
    t.string "units", default: "us", null: false
    t.string "theme", default: "system", null: false
    t.string "default_water"
    t.boolean "scientific_names_first", default: false, null: false
    t.boolean "strict_add_search", default: false, null: false
    t.boolean "default_tank_public", default: true, null: false
  end

  add_foreign_key "aquarium_species", "aquariums"
  add_foreign_key "aquarium_species", "species"
  add_foreign_key "aquariums", "users"
  add_foreign_key "species_aliases", "species"
end
