# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171115114020) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "points", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "rank", default: 0
    t.string "title"
    t.string "source"
    t.string "status"
    t.text "analysis"
    t.integer "rating"
    t.boolean "featured", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "topic_id"
    t.bigint "service_id"
    t.index ["service_id"], name: "index_points_on_service_id"
    t.index ["topic_id"], name: "index_points_on_topic_id"
    t.index ["user_id"], name: "index_points_on_user_id"
  end

  create_table "reasons", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id"
    t.bigint "point_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["point_id"], name: "index_reasons_on_point_id"
    t.index ["user_id"], name: "index_reasons_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tosdr_rating_id"
    t.string "grade"
    t.index ["tosdr_rating_id"], name: "index_services_on_tosdr_rating_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tosdr_ratings", force: :cascade do |t|
    t.integer "class_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "points", "services"
  add_foreign_key "points", "topics"
  add_foreign_key "points", "users"
  add_foreign_key "reasons", "points"
  add_foreign_key "reasons", "users"
  add_foreign_key "services", "tosdr_ratings"
end
