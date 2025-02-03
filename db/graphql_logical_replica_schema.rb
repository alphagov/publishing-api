ActiveRecord::Schema[8.0].define(version: 2025_01_28_101515) do
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
    t.index ["edition_id", "link_type"], name: "index_links_on_edition_id_and_link_type"
    t.index ["edition_id"], name: "index_links_on_edition_id"
    t.index ["link_set_id", "link_type"], name: "index_links_on_link_set_id_and_link_type"
    t.index ["link_set_id", "target_content_id"], name: "index_links_on_link_set_id_and_target_content_id"
    t.index ["link_set_id"], name: "index_links_on_link_set_id"
    t.index ["link_type"], name: "index_links_on_link_type"
    t.index ["target_content_id", "link_type"], name: "index_links_on_target_content_id_and_link_type"
    t.index ["target_content_id"], name: "index_links_on_target_content_id"
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

  # Note: fewer foreign keys, because we don't replicate all of the data
  add_foreign_key "editions", "documents"
  add_foreign_key "links", "link_sets"
end
