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

ActiveRecord::Schema.define(version: 20170719143106) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_limits", id: :serial, force: :cascade do |t|
    t.json "users", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "edition_id"
    t.json "auth_bypass_ids", default: [], null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_actions_on_edition_id"
    t.index ["event_id"], name: "index_actions_on_event_id"
    t.index ["link_set_id"], name: "index_actions_on_link_set_id"
  end

  create_table "change_notes", id: :serial, force: :cascade do |t|
    t.string "note", default: ""
    t.datetime "public_timestamp"
    t.integer "edition_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "document_id", null: false
    t.index ["edition_id"], name: "index_change_notes_on_edition_id"
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.uuid "content_id", null: false
    t.string "locale", null: false
    t.integer "stale_lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owning_document_id"
    t.index ["content_id", "locale"], name: "index_documents_on_content_id_and_locale", unique: true
  end

  create_table "editions", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "public_updated_at"
    t.json "details", default: {}
    t.json "routes", default: []
    t.json "redirects", default: []
    t.string "publishing_app"
    t.string "rendering_app"
    t.json "need_ids", default: []
    t.string "update_type"
    t.string "phase", default: "live"
    t.string "analytics_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "document_type"
    t.string "schema_name"
    t.datetime "first_published_at"
    t.datetime "last_edited_at"
    t.string "state", null: false
    t.integer "user_facing_version", default: 1, null: false
    t.string "base_path"
    t.string "content_store"
    t.integer "document_id", null: false
    t.string "description"
    t.string "publishing_request_id"
    t.index ["base_path", "content_store"], name: "index_editions_on_base_path_and_content_store", unique: true
    t.index ["created_at", "id"], name: "index_editions_on_created_at_and_id"
    t.index ["document_id", "content_store"], name: "index_editions_on_document_id_and_content_store", unique: true
    t.index ["document_id", "state"], name: "index_editions_on_document_id_and_state"
    t.index ["document_id", "user_facing_version"], name: "index_editions_on_document_id_and_user_facing_version", unique: true
    t.index ["document_id"], name: "index_editions_on_document_id"
    t.index ["document_type", "updated_at"], name: "index_editions_on_document_type_and_updated_at"
    t.index ["last_edited_at"], name: "index_editions_on_last_edited_at"
    t.index ["public_updated_at", "id"], name: "index_editions_on_public_updated_at_and_id"
    t.index ["public_updated_at"], name: "index_editions_on_public_updated_at"
    t.index ["publishing_app"], name: "index_editions_on_publishing_app"
    t.index ["rendering_app"], name: "index_editions_on_rendering_app"
    t.index ["state", "base_path"], name: "index_editions_on_state_and_base_path"
    t.index ["updated_at", "id"], name: "index_editions_on_updated_at_and_id"
    t.index ["updated_at"], name: "index_editions_on_updated_at"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.string "action", null: false
    t.json "payload", default: {}
    t.string "user_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "request_id"
    t.uuid "content_id"
    t.index ["content_id"], name: "index_events_on_content_id"
  end

  create_table "link_sets", id: :serial, force: :cascade do |t|
    t.uuid "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "stale_lock_version", default: 0
    t.index ["content_id"], name: "index_link_sets_on_content_id", unique: true
  end

  create_table "links", id: :serial, force: :cascade do |t|
    t.integer "link_set_id"
    t.uuid "target_content_id"
    t.string "link_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0, null: false
    t.integer "edition_id"
    t.index ["edition_id"], name: "index_links_on_edition_id"
    t.index ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id"
    t.index ["link_set_id"], name: "index_links_on_link_set_id"
    t.index ["link_type"], name: "index_links_on_link_type"
    t.index ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type"
    t.index ["target_content_id"], name: "index_links_on_target_content_id"
  end

  create_table "path_reservations", id: :serial, force: :cascade do |t|
    t.string "base_path", null: false
    t.string "publishing_app", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["base_path"], name: "index_path_reservations_on_base_path", unique: true
  end

  create_table "unpublishings", id: :serial, force: :cascade do |t|
    t.integer "edition_id", null: false
    t.string "type", null: false
    t.string "explanation"
    t.string "alternative_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "unpublished_at"
    t.json "redirects"
    t.index ["edition_id", "type"], name: "index_unpublishings_on_edition_id_and_type"
    t.index ["edition_id"], name: "index_unpublishings_on_edition_id"
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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "change_notes", "documents", on_delete: :cascade
  add_foreign_key "change_notes", "editions"
  add_foreign_key "editions", "documents"
  add_foreign_key "links", "editions", on_delete: :cascade
  add_foreign_key "links", "link_sets"
  add_foreign_key "unpublishings", "editions", on_delete: :cascade
end
