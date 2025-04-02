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

ActiveRecord::Schema[8.0].define(version: 2025_03_26_155406) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_limits", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "edition_id"
    t.jsonb "users", default: [], null: false
    t.jsonb "organisations", default: [], null: false
    t.index ["edition_id"], name: "index_access_limits_on_edition_id"
  end

  create_table "actions", id: :serial, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "locale"
    t.string "action", null: false
    t.uuid "user_uid"
    t.integer "edition_id"
    t.integer "link_set_id"
    t.integer "event_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "change_notes", id: :serial, force: :cascade do |t|
    t.text "note", default: ""
    t.datetime "public_timestamp", precision: nil
    t.integer "edition_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["edition_id"], name: "index_change_notes_on_edition_id"
  end

  create_table "content_id_aliases", force: :cascade do |t|
    t.string "name", null: false
    t.uuid "content_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_content_id_aliases_on_content_id"
    t.index ["name"], name: "index_content_id_aliases_on_name", unique: true
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "locale", null: false
    t.integer "stale_lock_version", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "owning_document_id"
    t.index ["content_id", "locale"], name: "index_documents_on_content_id_and_locale", unique: true
    t.index ["id", "locale"], name: "index_documents_on_id_and_locale"
  end

  create_table "editions", id: :serial, force: :cascade do |t|
    t.text "title"
    t.datetime "public_updated_at", precision: nil
    t.string "publishing_app"
    t.string "rendering_app"
    t.string "update_type"
    t.string "phase", default: "live"
    t.string "analytics_identifier"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "document_type"
    t.string "schema_name"
    t.datetime "first_published_at", precision: nil
    t.datetime "last_edited_at", precision: nil
    t.string "state", null: false
    t.integer "user_facing_version", default: 1, null: false
    t.text "base_path"
    t.string "content_store"
    t.integer "document_id", null: false
    t.text "description"
    t.string "publishing_request_id"
    t.datetime "major_published_at", precision: nil
    t.datetime "published_at", precision: nil
    t.datetime "publishing_api_first_published_at", precision: nil
    t.datetime "publishing_api_last_edited_at", precision: nil
    t.string "auth_bypass_ids", default: [], null: false, array: true
    t.jsonb "details", default: {}
    t.jsonb "routes", default: []
    t.jsonb "redirects", default: []
    t.uuid "last_edited_by_editor_id"
    t.index ["base_path", "content_store"], name: "index_editions_on_base_path_and_content_store", unique: true
    t.index ["document_id", "content_store"], name: "index_editions_on_document_id_and_content_store", unique: true
    t.index ["document_id", "document_type"], name: "index_editions_on_document_id_and_document_type_current", where: "((details ->> 'current'::text) = 'true'::text)"
    t.index ["document_id", "document_type"], name: "index_editions_on_document_id_and_document_type_live", where: "((content_store)::text = 'live'::text)"
    t.index ["document_id", "state"], name: "index_editions_on_document_id_and_state"
    t.index ["document_id", "user_facing_version"], name: "index_editions_on_document_id_and_user_facing_version", unique: true
    t.index ["document_id"], name: "index_editions_on_document_id"
    t.index ["document_type", "state"], name: "index_editions_on_document_type_and_state"
    t.index ["document_type", "updated_at"], name: "index_editions_on_document_type_and_updated_at"
    t.index ["id", "content_store"], name: "index_editions_on_id_and_content_store"
    t.index ["publishing_app"], name: "index_editions_on_publishing_app"
    t.index ["state", "base_path"], name: "index_editions_on_state_and_base_path"
    t.index ["updated_at", "id"], name: "index_editions_on_updated_at_and_id"
    t.index ["updated_at"], name: "index_editions_on_updated_at"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "action", null: false
    t.string "user_uid"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "request_id"
    t.uuid "content_id"
    t.jsonb "payload", default: {}
    t.index ["content_id"], name: "index_events_on_content_id"
  end

  create_table "expanded_links", force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "locale", null: false
    t.boolean "with_drafts", null: false
    t.bigint "payload_version", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "expanded_links", default: {}, null: false
    t.index ["content_id", "locale", "with_drafts"], name: "expanded_links_content_id_locale_with_drafts_index", unique: true
  end

  create_table "link_changes", force: :cascade do |t|
    t.uuid "source_content_id", null: false
    t.uuid "target_content_id", null: false
    t.string "link_type", null: false
    t.integer "change", null: false
    t.bigint "action_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at"], name: "index_link_changes_on_created_at", order: :desc
  end

  create_table "link_sets", id: :serial, force: :cascade do |t|
    t.uuid "content_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "stale_lock_version", default: 0
    t.index ["content_id"], name: "index_link_sets_on_content_id", unique: true
  end

  create_table "links", id: :serial, force: :cascade do |t|
    t.integer "link_set_id"
    t.uuid "target_content_id"
    t.string "link_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position", default: 0, null: false
    t.integer "edition_id"
    t.uuid "link_set_content_id"
    t.index ["edition_id", "link_type"], name: "index_links_on_edition_id_and_link_type"
    t.index ["edition_id"], name: "index_links_on_edition_id"
    t.index ["link_set_id", "link_type"], name: "index_links_on_link_set_id_and_link_type"
    t.index ["link_set_content_id", "link_type"], name: "index_links_on_link_set_content_id_and_link_type"
    t.index ["link_set_content_id", "target_content_id"], name: "index_links_on_link_set_content_id_and_target_content_id"
    t.index ["link_set_content_id"], name: "index_links_on_link_set_content_id"
    t.index ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id"
    t.index ["link_set_id"], name: "index_links_on_link_set_id"
    t.index ["link_type"], name: "index_links_on_link_type"
    t.index ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type"
    t.index ["target_content_id"], name: "index_links_on_target_content_id"
  end

  create_table "path_reservations", id: :serial, force: :cascade do |t|
    t.text "base_path", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["base_path"], name: "index_path_reservations_on_base_path", unique: true
  end

  create_table "statistics_caches", force: :cascade do |t|
    t.integer "unique_pageviews", null: false
    t.bigint "document_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_statistics_caches_on_document_id", unique: true
  end

  create_table "unpublishings", id: :serial, force: :cascade do |t|
    t.integer "edition_id", null: false
    t.string "type", null: false
    t.text "explanation"
    t.text "alternative_path"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "unpublished_at", precision: nil
    t.jsonb "redirects"
    t.index ["edition_id", "type"], name: "index_unpublishings_on_edition_id_and_type"
    t.index ["edition_id"], name: "index_unpublishings_on_edition_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.text "permissions"
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  add_foreign_key "change_notes", "editions"
  add_foreign_key "editions", "documents"
  add_foreign_key "link_changes", "actions", on_delete: :cascade
  add_foreign_key "links", "editions", on_delete: :cascade
  add_foreign_key "links", "link_sets"
  add_foreign_key "links", "link_sets", column: "link_set_content_id", primary_key: "content_id"
  add_foreign_key "unpublishings", "editions", on_delete: :cascade
end
