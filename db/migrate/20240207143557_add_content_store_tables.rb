class AddContentStoreTables < ActiveRecord::Migration[7.1]
  def change
    create_table "content_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "content_store", null: false
      t.string "base_path"
      t.string "content_id"
      t.string "title"
      t.jsonb "description", default: {"value"=>nil}
      t.string "document_type"
      t.string "content_purpose_document_supertype", default: ""
      t.string "content_purpose_subgroup", default: ""
      t.string "content_purpose_supergroup", default: ""
      t.string "email_document_supertype", default: ""
      t.string "government_document_supertype", default: ""
      t.string "navigation_document_supertype", default: ""
      t.string "search_user_need_document_supertype", default: ""
      t.string "user_journey_document_supertype", default: ""
      t.string "schema_name"
      t.string "locale", default: "en"
      t.datetime "first_published_at"
      t.datetime "public_updated_at"
      t.datetime "publishing_scheduled_at"
      t.jsonb "details", default: {}
      t.string "publishing_app"
      t.string "rendering_app"
      t.jsonb "routes", default: []
      t.jsonb "redirects", default: []
      t.jsonb "expanded_links", default: {}
      t.jsonb "access_limited", default: {}
      t.string "auth_bypass_ids", default: [], array: true
      t.string "phase", default: "live"
      t.string "analytics_identifier"
      t.integer "payload_version"
      t.jsonb "withdrawn_notice", default: {}
      t.string "publishing_request_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "_id"
      t.bigint "scheduled_publishing_delay_seconds"
      t.index [:content_store, :base_path], name: "index_content_items_on_base_path", unique: true
      t.index [:content_store, :content_id], name: "index_content_items_on_content_id"
      t.index [:content_store, :created_at], name: "index_content_items_on_created_at"
      t.index [:redirects], name: "ix_ci_redirects_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
      t.index [:content_store, :routes], name: "index_content_items_on_routes", using: :gin
      t.index [:routes], name: "ix_ci_routes_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
      t.index [:content_store, :updated_at], name: "index_content_items_on_updated_at"
    end
  
    create_table "publish_intents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "base_path"
      t.datetime "publish_time"
      t.string "publishing_app"
      t.string "rendering_app"
      t.jsonb "routes", default: []
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index [:base_path], name: "index_publish_intents_on_base_path", unique: true
      t.index [:created_at], name: "index_publish_intents_on_created_at"
      t.index [:publish_time], name: "index_publish_intents_on_publish_time"
      t.index [:routes], name: "index_publish_intents_on_routes", using: :gin
      t.index [:routes], name: "ix_pi_routes_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
      t.index [:updated_at], name: "index_publish_intents_on_updated_at"
    end
  
    create_table "scheduled_publishing_log_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "base_path"
      t.string "document_type"
      t.datetime "scheduled_publication_time"
      t.bigint "delay_in_milliseconds"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "mongo_id"
      t.index [:base_path], name: "ix_scheduled_pub_log_base_path"
      t.index [:created_at], name: "ix_scheduled_pub_log_created"
      t.index [:mongo_id], name: "index_scheduled_publishing_log_entries_on_mongo_id"
      t.index [:scheduled_publication_time], name: "ix_scheduled_pub_log_time"
    end
  end
end
