# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160315123002) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_limits", force: :cascade do |t|
    t.json     "users",           default: [], null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "content_item_id"
  end

  create_table "content_items", force: :cascade do |t|
    t.string   "content_id"
    t.string   "title"
    t.string   "format"
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
  end

  add_index "content_items", ["content_id"], name: "index_content_items_on_content_id", using: :btree
  add_index "content_items", ["document_type"], name: "index_content_items_on_document_type", using: :btree
  add_index "content_items", ["format"], name: "index_content_items_on_format", using: :btree
  add_index "content_items", ["public_updated_at"], name: "index_content_items_on_public_updated_at", using: :btree
  add_index "content_items", ["publishing_app"], name: "index_content_items_on_publishing_app", using: :btree
  add_index "content_items", ["rendering_app"], name: "index_content_items_on_rendering_app", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "action",                  null: false
    t.json     "payload",    default: {}, null: false
    t.string   "user_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "link_sets", force: :cascade do |t|
    t.string   "content_id"
    t.json     "legacy_links", default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "link_sets", ["content_id"], name: "index_link_sets_on_content_id", unique: true, using: :btree

  create_table "links", force: :cascade do |t|
    t.integer  "link_set_id"
    t.string   "target_content_id"
    t.string   "link_type",         null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.json     "passthrough_hash"
  end

  add_index "links", ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id", using: :btree
  add_index "links", ["link_set_id"], name: "index_links_on_link_set_id", using: :btree
  add_index "links", ["link_type"], name: "index_links_on_link_type", using: :btree
  add_index "links", ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type", using: :btree
  add_index "links", ["target_content_id"], name: "index_links_on_target_content_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "base_path",       null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "locations", ["base_path"], name: "index_locations_on_base_path", using: :btree
  add_index "locations", ["content_item_id", "base_path"], name: "index_locations_on_content_item_id_and_base_path", using: :btree

  create_table "lock_versions", force: :cascade do |t|
    t.integer  "target_id",               null: false
    t.string   "target_type",             null: false
    t.integer  "number",      default: 0, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "lock_versions", ["target_id", "target_type"], name: "index_lock_versions_on_target_id_and_target_type", using: :btree

  create_table "path_reservations", force: :cascade do |t|
    t.string   "base_path",      null: false
    t.string   "publishing_app", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "path_reservations", ["base_path"], name: "index_path_reservations_on_base_path", unique: true, using: :btree

  create_table "states", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "name",            null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "states", ["content_item_id", "name"], name: "index_states_on_content_item_id_and_name", using: :btree

  create_table "translations", force: :cascade do |t|
    t.integer  "content_item_id", null: false
    t.string   "locale",          null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "translations", ["content_item_id", "locale"], name: "index_translations_on_content_item_id_and_locale", using: :btree

  create_table "user_facing_versions", force: :cascade do |t|
    t.integer  "content_item_id",             null: false
    t.integer  "number",          default: 0, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "user_facing_versions", ["content_item_id", "number"], name: "index_user_facing_versions_on_content_item_id_and_number", using: :btree

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

  add_foreign_key "links", "link_sets"
end
