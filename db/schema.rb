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

ActiveRecord::Schema.define(version: 20170111161439) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_limits", force: :cascade do |t|
    t.json     "users",           default: [], null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "content_item_id"
    t.index ["content_item_id"], name: "index_access_limits_on_content_item_id", using: :btree
  end

  create_table "actions", force: :cascade do |t|
    t.uuid     "content_id",      null: false
    t.string   "locale"
    t.string   "action",          null: false
    t.uuid     "user_uid"
    t.integer  "content_item_id"
    t.integer  "link_set_id"
    t.integer  "event_id",        null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["content_item_id"], name: "index_actions_on_content_item_id", using: :btree
    t.index ["event_id"], name: "index_actions_on_event_id", using: :btree
    t.index ["link_set_id"], name: "index_actions_on_link_set_id", using: :btree
  end

  create_table "change_notes", force: :cascade do |t|
    t.string   "note",             default: ""
    t.datetime "public_timestamp"
    t.integer  "content_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_id"
    t.index ["content_id"], name: "index_change_notes_on_content_id", using: :btree
    t.index ["content_item_id"], name: "index_change_notes_on_content_item_id", using: :btree
  end

  create_table "content_items", force: :cascade do |t|
    t.string   "title"
    t.datetime "public_updated_at"
    t.json     "details",              default: {}
    t.json     "routes",               default: []
    t.json     "redirects",            default: []
    t.string   "publishing_app"
    t.string   "rendering_app"
    t.json     "need_ids",             default: []
    t.string   "update_type"
    t.string   "phase",                default: "live"
    t.string   "analytics_identifier"
    t.json     "description",          default: {"value"=>nil}
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "document_type"
    t.string   "schema_name"
    t.datetime "first_published_at"
    t.datetime "last_edited_at"
    t.string   "state",                                         null: false
    t.integer  "user_facing_version",  default: 1,              null: false
    t.string   "base_path"
    t.string   "content_store"
    t.uuid     "content_id",                                    null: false
    t.string   "locale",                                        null: false
    t.integer  "document_id",                                   null: false
    t.index ["base_path", "content_store"], name: "index_content_items_on_base_path_and_content_store", unique: true, using: :btree
    t.index ["content_id", "locale", "content_store"], name: "index_content_items_on_content_id_and_locale_and_content_store", unique: true, using: :btree
    t.index ["content_id", "locale", "user_facing_version"], name: "index_unique_ufv_content_id_locale", unique: true, using: :btree
    t.index ["content_id", "state", "locale"], name: "index_content_items_on_content_id_and_state_and_locale", using: :btree
    t.index ["content_id"], name: "index_content_items_on_content_id", using: :btree
    t.index ["document_id"], name: "index_content_items_on_document_id", using: :btree
    t.index ["document_id", "content_store"], name: "index_content_items_on_document_id_and_content_store", unique: true, using: :btree
    t.index ["document_id", "state"], name: "index_content_items_on_document_id_and_state", using: :btree
    t.index ["document_id", "user_facing_version"], name: "index_content_items_on_document_id_and_user_facing_version", unique: true, using: :btree
    t.index ["document_type"], name: "index_content_items_on_document_type", using: :btree
    t.index ["last_edited_at"], name: "index_content_items_on_last_edited_at", using: :btree
    t.index ["public_updated_at"], name: "index_content_items_on_public_updated_at", using: :btree
    t.index ["publishing_app"], name: "index_content_items_on_publishing_app", using: :btree
    t.index ["rendering_app"], name: "index_content_items_on_rendering_app", using: :btree
    t.index ["state", "base_path"], name: "index_content_items_on_state_and_base_path", using: :btree
    t.index ["updated_at"], name: "index_content_items_on_updated_at", using: :btree
  end

  create_table "documents", force: :cascade do |t|
    t.uuid    "content_id",                     null: false
    t.string  "locale",                         null: false
    t.integer "stale_lock_version", default: 0, null: false
    t.index ["content_id", "locale"], name: "index_documents_on_content_id_and_locale", unique: true, using: :btree
  end

  create_table "events", force: :cascade do |t|
    t.string   "action",                  null: false
    t.json     "payload",    default: {}
    t.string   "user_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "request_id"
    t.uuid     "content_id"
    t.index ["content_id"], name: "index_events_on_content_id", using: :btree
  end

  create_table "link_sets", force: :cascade do |t|
    t.uuid     "content_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "stale_lock_version", default: 0
    t.index ["content_id"], name: "index_link_sets_on_content_id", unique: true, using: :btree
  end

  create_table "links", force: :cascade do |t|
    t.integer  "link_set_id"
    t.uuid     "target_content_id"
    t.string   "link_type",                     null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "position",          default: 0, null: false
    t.index ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id", using: :btree
    t.index ["link_set_id"], name: "index_links_on_link_set_id", using: :btree
    t.index ["link_type"], name: "index_links_on_link_type", using: :btree
    t.index ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type", using: :btree
    t.index ["target_content_id"], name: "index_links_on_target_content_id", using: :btree
  end

  create_table "locations", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "base_path",       null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["base_path"], name: "index_locations_on_base_path", using: :btree
    t.index ["content_item_id", "base_path"], name: "index_locations_on_content_item_id_and_base_path", using: :btree
  end

  create_table "lock_versions", force: :cascade do |t|
    t.integer  "target_id",               null: false
    t.string   "target_type",             null: false
    t.integer  "number",      default: 0, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["target_id", "target_type"], name: "index_lock_versions_on_target_id_and_target_type", using: :btree
  end

  create_table "path_reservations", force: :cascade do |t|
    t.string   "base_path",      null: false
    t.string   "publishing_app", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["base_path"], name: "index_path_reservations_on_base_path", unique: true, using: :btree
  end

  create_table "states", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "name",            null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["content_item_id", "name"], name: "index_states_on_content_item_id_and_name", using: :btree
    t.index ["content_item_id"], name: "index_states_on_content_item_id", using: :btree
  end

  create_table "translations", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "locale",          null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["content_item_id", "locale"], name: "index_translations_on_content_item_id_and_locale", using: :btree
    t.index ["content_item_id"], name: "index_translations_on_content_item_id", using: :btree
  end

  create_table "unpublishings", force: :cascade do |t|
    t.integer  "content_item_id",  null: false
    t.string   "type",             null: false
    t.string   "explanation"
    t.string   "alternative_path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "unpublished_at"
    t.index ["content_item_id", "type"], name: "index_unpublishings_on_content_item_id_and_type", using: :btree
    t.index ["content_item_id"], name: "index_unpublishings_on_content_item_id", using: :btree
  end

  create_table "user_facing_versions", force: :cascade do |t|
    t.integer  "content_item_id",             null: false
    t.integer  "number",          default: 0, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["content_item_id", "number"], name: "index_user_facing_versions_on_content_item_id_and_number", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "uid"
    t.string   "organisation_slug"
    t.string   "organisation_content_id"
    t.string   "app_name"
    t.text     "permissions"
    t.boolean  "remotely_signed_out",     default: false
    t.boolean  "disabled",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "change_notes", "content_items"
  add_foreign_key "content_items", "documents"
  add_foreign_key "links", "link_sets"
end
