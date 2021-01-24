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

ActiveRecord::Schema.define(version: 2020_12_15_125020) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "case_comments", force: :cascade do |t|
    t.string "summary"
    t.bigint "case_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_comments_on_case_id"
    t.index ["user_id"], name: "index_case_comments_on_user_id"
  end

  create_table "cases", force: :cascade do |t|
    t.string "classification"
    t.integer "score"
    t.string "title"
    t.text "description"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "privacy_related"
    t.index ["topic_id"], name: "index_cases_on_topic_id"
  end

  create_table "document_comments", force: :cascade do |t|
    t.string "summary"
    t.bigint "document_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_comments_on_document_id"
    t.index ["user_id"], name: "index_document_comments_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "xpath"
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "service_id"
    t.boolean "reviewed"
    t.bigint "user_id"
    t.string "status"
    t.index ["service_id"], name: "index_documents_on_service_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "point_comments", force: :cascade do |t|
    t.bigint "point_id"
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["point_id"], name: "index_point_comments_on_point_id"
    t.index ["user_id"], name: "index_point_comments_on_user_id"
  end

  create_table "points", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "rank", default: 0
    t.string "title"
    t.string "source"
    t.string "status"
    t.text "analysis"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "service_id"
    t.string "quoteText"
    t.bigint "case_id"
    t.string "oldId"
    t.text "point_change"
    t.boolean "service_needs_rating_update", default: false
    t.integer "quoteStart"
    t.integer "quoteEnd"
    t.bigint "document_id"
    t.index ["case_id"], name: "index_points_on_case_id"
    t.index ["document_id"], name: "index_points_on_document_id"
    t.index ["service_id"], name: "index_points_on_service_id"
    t.index ["user_id"], name: "index_points_on_user_id"
  end

  create_table "reasons", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id"
    t.bigint "point_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.index ["point_id"], name: "index_reasons_on_point_id"
    t.index ["user_id"], name: "index_reasons_on_user_id"
  end

  create_table "service_comments", force: :cascade do |t|
    t.string "summary"
    t.bigint "service_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_service_comments_on_service_id"
    t.index ["user_id"], name: "index_service_comments_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wikipedia"
    t.string "keywords"
    t.string "related"
    t.string "slug"
    t.boolean "is_comprehensively_reviewed", default: false, null: false
    t.bigint "user_id"
    t.string "rating"
    t.string "status"
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "spams", force: :cascade do |t|
    t.string "spammable_type"
    t.bigint "spammable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "flagged_by_admin_or_curator", default: false
    t.boolean "cleaned", default: false
    t.index ["spammable_type", "spammable_id"], name: "index_spams_on_spammable_type_and_spammable_id"
  end

  create_table "topic_comments", force: :cascade do |t|
    t.string "summary"
    t.bigint "topic_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_comments_on_topic_id"
    t.index ["user_id"], name: "index_topic_comments_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "oldId"
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
    t.boolean "curator", default: false
    t.boolean "deactivated", default: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "bot", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "case_comments", "cases"
  add_foreign_key "case_comments", "users"
  add_foreign_key "cases", "topics"
  add_foreign_key "document_comments", "documents"
  add_foreign_key "document_comments", "users"
  add_foreign_key "documents", "services"
  add_foreign_key "documents", "users"
  add_foreign_key "point_comments", "points"
  add_foreign_key "point_comments", "users"
  add_foreign_key "points", "cases"
  add_foreign_key "points", "documents"
  add_foreign_key "points", "services"
  add_foreign_key "points", "users"
  add_foreign_key "reasons", "points"
  add_foreign_key "reasons", "users"
  add_foreign_key "service_comments", "services"
  add_foreign_key "service_comments", "users"
  add_foreign_key "services", "users"
  add_foreign_key "topic_comments", "topics"
  add_foreign_key "topic_comments", "users"
end
