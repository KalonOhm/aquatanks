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

ActiveRecord::Schema[7.0].define(version: 2023_02_24_013510) do
  create_table "aquariums", force: :cascade do |t|
    t.integer "size"
    t.string "water_type"
    t.string "filter"
    t.boolean "plants"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "aquariums_fishes", force: :cascade do |t|
    t.integer "aquarium_id"
    t.integer "fish_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aquarium_id"], name: "index_aquariums_fishes_on_aquarium_id"
    t.index ["fish_id"], name: "index_aquariums_fishes_on_fish_id"
  end

  create_table "fishes", force: :cascade do |t|
    t.string "common_name"
    t.string "taxonomic_name"
    t.string "image_url", default: "https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/60610/empty-aquarium-clipart-md.png"
    t.string "size"
    t.string "other_remarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
