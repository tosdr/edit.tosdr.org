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

ActiveRecord::Schema.define(version: 2023_08_15_093829) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "activation", id: :serial, force: :cascade do |t|
    t.text "code", null: false
    t.index ["code"], name: "uq__activation__code", unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "alembic_version", primary_key: "version_num", id: { type: :string, limit: 32 }, force: :cascade do |t|
  end

  create_table "annotation", id: :uuid, default: -> { "uuid_generate_v1mc()" }, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "userid", null: false
    t.text "groupid", default: "__world__", null: false
    t.text "text"
    t.text "text_rendered"
    t.text "tags", array: true
    t.boolean "shared", default: false, null: false
    t.text "target_uri"
    t.text "target_uri_normalized"
    t.jsonb "target_selectors", default: []
    t.uuid "references", array: true
    t.jsonb "extra", default: {}, null: false
    t.boolean "deleted", default: false, null: false
    t.integer "document_id", null: false
    t.index "(\"references\"[1])", name: "ix__annotation_thread_root"
    t.index ["groupid"], name: "ix__annotation_groupid"
    t.index ["tags"], name: "ix__annotation_tags", using: :gin
    t.index ["updated"], name: "ix__annotation_updated"
    t.index ["userid"], name: "ix__annotation_userid"
  end

  create_table "annotation_moderation", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.uuid "annotation_id", null: false
    t.index ["annotation_id"], name: "uq__annotation_moderation__annotation_id", unique: true
  end

# Could not dump table "authclient" because of following StandardError
#   Unknown type 'authclient_grant_type' for column 'grant_type'

  create_table "authticket", id: :text, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.datetime "expires", null: false
    t.integer "user_id", null: false
    t.text "user_userid", null: false
  end

  create_table "authzcode", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.integer "user_id", null: false
    t.uuid "authclient_id", null: false
    t.text "code", null: false
    t.datetime "expires", null: false
    t.index ["code"], name: "uq__authzcode__code", unique: true
  end

  create_table "blocklist", id: :serial, force: :cascade do |t|
    t.text "uri", null: false
    t.index ["uri"], name: "uq__blocklist__uri", unique: true
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
    t.string "docbot_regex"
    t.index ["topic_id"], name: "index_cases_on_topic_id"
  end

  create_table "docbot_records", force: :cascade do |t|
    t.string "model_version"
    t.bigint "document_id"
    t.bigint "case_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "char_start"
    t.integer "char_end"
    t.decimal "ml_score"
    t.index ["case_id"], name: "index_docbot_records_on_case_id"
    t.index ["document_id"], name: "index_docbot_records_on_document_id"
  end

  create_table "document", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "title"
    t.text "web_uri"
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

  create_table "document_meta", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "claimant", null: false
    t.text "claimant_normalized", null: false
    t.text "type", null: false
    t.text "value", null: false, array: true
    t.integer "document_id", null: false
    t.index ["claimant_normalized", "type"], name: "uq__document_meta__claimant_normalized", unique: true
    t.index ["document_id"], name: "ix__document_meta_document_id"
    t.index ["updated"], name: "ix__document_meta_updated"
  end

  create_table "document_uri", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "claimant", null: false
    t.text "claimant_normalized", null: false
    t.text "uri", null: false
    t.text "uri_normalized", null: false
    t.text "type", default: "", null: false
    t.text "content_type", default: "", null: false
    t.integer "document_id", null: false
    t.index ["claimant_normalized", "uri_normalized", "type", "content_type"], name: "uq__document_uri__claimant_normalized", unique: true
    t.index ["document_id"], name: "ix__document_uri_document_id"
    t.index ["updated"], name: "ix__document_uri_updated"
    t.index ["uri_normalized"], name: "ix__document_uri_uri_normalized"
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
    t.string "crawler_server"
    t.index ["service_id"], name: "index_documents_on_service_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "feature", id: :serial, force: :cascade do |t|
    t.text "name", null: false
    t.boolean "everyone", default: false, null: false
    t.boolean "admins", default: false, null: false
    t.boolean "staff", default: false, null: false
    t.index ["name"], name: "uq__feature__name", unique: true
  end

  create_table "featurecohort", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "name", null: false
    t.index ["name"], name: "ix__featurecohort_name"
  end

  create_table "featurecohort_feature", id: :serial, force: :cascade do |t|
    t.integer "cohort_id", null: false
    t.integer "feature_id", null: false
    t.index ["cohort_id", "feature_id"], name: "uq__featurecohort_feature__cohort_id", unique: true
  end

  create_table "featurecohort_user", id: :serial, force: :cascade do |t|
    t.integer "cohort_id", null: false
    t.integer "user_id", null: false
    t.index ["cohort_id", "user_id"], name: "uq__featurecohort_user__cohort_id", unique: true
  end

  create_table "flag", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.uuid "annotation_id", null: false
    t.integer "user_id", null: false
    t.index ["annotation_id", "user_id"], name: "uq__flag__annotation_id", unique: true
    t.index ["user_id"], name: "ix__flag_user_id"
  end

# Could not dump table "group" because of following StandardError
#   Unknown type 'group_joinable_by' for column 'joinable_by'

  create_table "groupscope", id: :serial, force: :cascade do |t|
    t.integer "group_id", null: false
    t.text "origin", null: false
    t.text "path"
    t.index ["origin", "path"], name: "ix__groupscope__scope"
  end

  create_table "job", id: :integer, default: nil, force: :cascade do |t|
    t.text "name", null: false
    t.datetime "enqueued_at", default: -> { "now()" }, null: false
    t.datetime "scheduled_at", default: -> { "now()" }, null: false
    t.datetime "expires_at", default: -> { "(now() + 'P30D'::interval)" }, null: false
    t.integer "priority", null: false
    t.text "tag", null: false
    t.jsonb "kwargs", default: {}, null: false
  end

  create_table "organization", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "pubid", null: false
    t.text "name", null: false
    t.text "logo"
    t.text "authority", null: false
    t.index ["name"], name: "ix__organization_name"
    t.index ["pubid"], name: "uq__organization__pubid", unique: true
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
    t.string "quote_text"
    t.bigint "case_id"
    t.string "old_id"
    t.text "point_change"
    t.boolean "service_needs_rating_update", default: false
    t.integer "quote_start"
    t.integer "quote_end"
    t.bigint "document_id"
    t.string "annotation_ref"
    t.decimal "ml_score"
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

  create_table "setting", primary_key: "key", id: :text, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "value"
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

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.text "uri", null: false
    t.string "type", limit: 64, null: false
    t.boolean "active", null: false
    t.index ["uri"], name: "subs_uri_idx_subscriptions"
  end

  create_table "token", id: :serial, force: :cascade do |t|
    t.datetime "created", default: -> { "now()" }, null: false
    t.datetime "updated", default: -> { "now()" }, null: false
    t.text "userid", null: false
    t.text "value", null: false
    t.datetime "expires"
    t.text "refresh_token"
    t.datetime "refresh_token_expires"
    t.uuid "authclient_id"
    t.index ["refresh_token"], name: "uq__token__refresh_token", unique: true
    t.index ["value"], name: "uq__token__value", unique: true
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

  create_table "user", id: :serial, force: :cascade do |t|
    t.text "username", null: false
    t.text "authority", null: false
    t.text "display_name"
    t.text "description"
    t.text "location"
    t.text "uri"
    t.text "orcid"
    t.boolean "admin", default: false, null: false
    t.boolean "staff", default: false, null: false
    t.boolean "nipsa", default: false, null: false
    t.boolean "sidebar_tutorial_dismissed", default: false
    t.datetime "privacy_accepted"
    t.boolean "comms_opt_in"
    t.text "email"
    t.datetime "last_login_date"
    t.datetime "registered_date", default: -> { "now()" }, null: false
    t.datetime "activation_date"
    t.integer "activation_id"
    t.text "password"
    t.datetime "password_updated"
    t.text "salt"
    t.index "lower(replace(username, '.'::text, ''::text)), authority", name: "ix__user__userid", unique: true
    t.index ["email", "authority"], name: "uq__user__email", unique: true
    t.index ["nipsa"], name: "ix__user__nipsa", where: "(nipsa IS TRUE)"
  end

  create_table "user_group", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "group_id", null: false
    t.index ["user_id", "group_id"], name: "uq__user_group__user_id", unique: true
  end

  create_table "user_identity", id: :serial, force: :cascade do |t|
    t.text "provider", null: false
    t.text "provider_unique_id", null: false
    t.integer "user_id", null: false
    t.index ["provider", "provider_unique_id"], name: "uq__user_identity__provider", unique: true
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
    t.string "h_key"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "annotation", "document", name: "fk__annotation__document_id__document"
  add_foreign_key "annotation_moderation", "annotation", name: "fk__annotation_moderation__annotation_id__annotation", on_delete: :cascade
  add_foreign_key "authticket", "\"user\"", column: "user_id", name: "fk__authticket__user_id__user", on_delete: :cascade
  add_foreign_key "authzcode", "\"user\"", column: "user_id", name: "fk__authzcode__user_id__user", on_delete: :cascade
  add_foreign_key "authzcode", "authclient", name: "fk__authzcode__authclient_id__authclient", on_delete: :cascade
  add_foreign_key "case_comments", "cases"
  add_foreign_key "case_comments", "users"
  add_foreign_key "cases", "topics"
  add_foreign_key "docbot_records", "cases"
  add_foreign_key "docbot_records", "documents"
  add_foreign_key "document_comments", "documents"
  add_foreign_key "document_comments", "users"
  add_foreign_key "document_meta", "document", name: "fk__document_meta__document_id__document"
  add_foreign_key "document_uri", "document", name: "fk__document_uri__document_id__document"
  add_foreign_key "documents", "services"
  add_foreign_key "documents", "users"
  add_foreign_key "featurecohort_feature", "feature", name: "fk__featurecohort_feature__feature_id__feature", on_delete: :cascade
  add_foreign_key "featurecohort_feature", "featurecohort", column: "cohort_id", name: "fk__featurecohort_feature__cohort_id__featurecohort"
  add_foreign_key "featurecohort_user", "\"user\"", column: "user_id", name: "fk__featurecohort_user__user_id__user"
  add_foreign_key "featurecohort_user", "featurecohort", column: "cohort_id", name: "fk__featurecohort_user__cohort_id__featurecohort"
  add_foreign_key "flag", "\"user\"", column: "user_id", name: "fk__flag__user_id__user", on_delete: :cascade
  add_foreign_key "flag", "annotation", name: "fk__flag__annotation_id__annotation", on_delete: :cascade
  add_foreign_key "group", "\"user\"", column: "creator_id", name: "fk__group__creator_id__user"
  add_foreign_key "group", "organization", name: "fk__group__organization_id__organization"
  add_foreign_key "groupscope", "\"group\"", column: "group_id", name: "fk__groupscope__group_id__group", on_delete: :cascade
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
  add_foreign_key "token", "authclient", name: "fk__token__authclient_id__authclient", on_delete: :cascade
  add_foreign_key "topic_comments", "topics"
  add_foreign_key "topic_comments", "users"
  add_foreign_key "user", "activation", name: "fk__user__activation_id__activation"
  add_foreign_key "user_group", "\"group\"", column: "group_id", name: "fk__user_group__group_id__group"
  add_foreign_key "user_group", "\"user\"", column: "user_id", name: "fk__user_group__user_id__user"
  add_foreign_key "user_identity", "\"user\"", column: "user_id", name: "fk__user_identity__user_id__user", on_delete: :cascade
end
