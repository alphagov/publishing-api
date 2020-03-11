class NewObjectModel < ActiveRecord::Migration[4.2]
  class DraftContentItem < ApplicationRecord; end
  class LiveContentItem < ApplicationRecord; end
  class ContentItem < ApplicationRecord; end
  class State < ApplicationRecord; end
  class Translation < ApplicationRecord; end
  class Location < ApplicationRecord; end
  class LockVersion < ApplicationRecord; end
  class UserFacingVersion < ApplicationRecord; end
  class AcceessLimit < ApplicationRecord; end

  def up
    create_table :locations do |t|
      t.references :content_item
      t.string :base_path, null: false

      t.timestamps null: false
    end
    change_column_null :locations, :content_item_id, false
    add_index :locations, %i[content_item_id base_path]

    create_table :translations do |t|
      t.references :content_item
      t.string :locale, null: false

      t.timestamps null: false
    end
    change_column_null :translations, :content_item_id, false
    add_index :translations, %i[content_item_id locale]

    create_table :states do |t|
      t.references :content_item
      t.string :name, null: false

      t.timestamps null: false
    end
    change_column_null :states, :content_item_id, false
    add_index :states, %i[content_item_id name]

    create_table :user_facing_versions do |t|
      t.references :content_item
      t.integer :number, default: 0, null: false

      t.timestamps null: false
    end
    change_column_null :user_facing_versions, :content_item_id, false
    add_index :user_facing_versions, %i[content_item_id number]

    create_table "lock_versions" do |t|
      t.integer  "target_id",               null: false
      t.string   "target_type",             null: false
      t.integer  "number", default: 0, null: false
      t.datetime "created_at",              null: false
      t.datetime "updated_at",              null: false
    end

    create_table :content_items do |t|
      t.string   "content_id"
      t.string   "title"
      t.string   "format"
      t.datetime "public_updated_at"
      t.json     "access_limited",       default: {}
      t.json     "details",              default: {}
      t.json     "routes",               default: []
      t.json     "redirects",            default: []
      t.string   "publishing_app"
      t.string   "rendering_app"
      t.json     "need_ids", default: []
      t.string   "update_type"
      t.string   "phase", default: "live"
      t.string   "analytics_identifier"
      t.json     "description", default: { "value" => nil }
      t.integer  "live_content_item_id"
      t.integer  "draft_content_item_id"

      t.timestamps null: false
    end

    # No longer polymorphic
    add_column :access_limits, :content_item_id, :integer
    change_column_null :access_limits, :target_id, true
    change_column_null :access_limits, :target_type, true

    content_item_sql = '
    INSERT INTO "content_items" (
                "content_id",
                "title",
                "format",
                "public_updated_at",
                "details",
                "routes",
                "redirects",
                "publishing_app",
                "rendering_app",
                "need_ids",
                "update_type",
                "phase",
                "analytics_identifier",
                "description",
                "live_content_item_id",
                "draft_content_item_id",
                "created_at",
                "updated_at"
              )
        SELECT
          "content_id",
          "title",
          "format",
          "public_updated_at",
          "details",
          "routes",
          "redirects",
          "publishing_app",
          "rendering_app",
          "need_ids",
          "update_type",
          "phase",
          "analytics_identifier",
          "description",
          "id" AS "live_content_item_id",
          NULL AS "draft_content_item_id",
          NOW() AS "created_at",
          NOW() AS "updated_at"
        FROM "live_content_items"
      UNION ALL
        SELECT
          "content_id",
          "title",
          "format",
          "public_updated_at",
          "details",
          "routes",
          "redirects",
          "publishing_app",
          "rendering_app",
          "need_ids",
          "update_type",
          "phase",
          "analytics_identifier",
          "description",
          NULL AS "live_content_item_id",
          "id" AS "draft_content_item_id",
          NOW() AS "created_at",
          NOW() AS "updated_at"
        FROM "draft_content_items"
    '

    say_with_time "Copying content items" do
      ActiveRecord::Base.connection.execute(content_item_sql)
    end

    puts "LiveContentItems: #{LiveContentItem.count}"
    puts "DraftContentItems: #{DraftContentItem.count}"
    puts "ContentItems: #{ContentItem.count}"

    state_sql = '
      INSERT INTO "states" (
                  "content_item_id",
                  "name",
                  "created_at",
                  "updated_at"
      )
      SELECT
        "id",
        CASE WHEN "live_content_item_id" IS NOT NULL THEN \'published\'
             WHEN "draft_content_item_id" IS NOT NULL THEN \'draft\'
        END AS "name",
        NOW(),
        NOW()
      FROM "content_items"
    '

    say_with_time "Creating states" do
      ActiveRecord::Base.connection.execute(state_sql)
    end

    puts "States: #{State.count}, Content Items: #{ContentItem.count}"

    translation_sql = '
      INSERT INTO "translations" (
                  "content_item_id",
                  "locale",
                  "created_at",
                  "updated_at"
      )
      SELECT
        "content_items"."id",
        CASE WHEN "content_items"."live_content_item_id" IS NOT NULL THEN "live_content_items"."locale"
             WHEN "content_items"."draft_content_item_id" IS NOT NULL THEN "draft_content_items"."locale"
        END AS "locale",
        NOW(),
        NOW()
      FROM "content_items"
      LEFT JOIN "live_content_items" ON "content_items"."live_content_item_id" = "live_content_items"."id"
      LEFT JOIN "draft_content_items" ON "content_items"."draft_content_item_id" = "draft_content_items"."id"
    '

    say_with_time "Creating translations" do
      ActiveRecord::Base.connection.execute(translation_sql)
    end

    puts "Translations: #{Translation.count}, Content Items: #{ContentItem.count}"

    location_sql = '
      INSERT INTO "locations" (
                  "content_item_id",
                  "base_path",
                  "created_at",
                  "updated_at"
      )
      SELECT
        "content_items"."id",
        CASE WHEN "content_items"."live_content_item_id" IS NOT NULL THEN "live_content_items"."base_path"
             WHEN "content_items"."draft_content_item_id" IS NOT NULL THEN "draft_content_items"."base_path"
        END AS "base_path",
        NOW(),
        NOW()
      FROM "content_items"
      LEFT JOIN "live_content_items" ON "content_items"."live_content_item_id" = "live_content_items"."id"
      LEFT JOIN "draft_content_items" ON "content_items"."draft_content_item_id" = "draft_content_items"."id"
    '

    say_with_time "Creating locations" do
      ActiveRecord::Base.connection.execute(location_sql)
    end

    puts "Locations: #{Location.count}, Content Items: #{ContentItem.count}"

    lock_version_for_content_items_sql = '
      INSERT INTO "lock_versions" (
                  "target_id",
                  "target_type",
                  "number",
                  "created_at",
                  "updated_at"
      )
      SELECT
        "content_items"."id",
        \'ContentItem\',
        COALESCE("lv"."number", "dv"."number") AS "number",
        NOW(),
        NOW()
      FROM "content_items"
      LEFT JOIN "live_content_items" AS "lci" ON "content_items"."live_content_item_id" = "lci"."id"
      LEFT JOIN "draft_content_items" AS "dci" ON "content_items"."draft_content_item_id" = "dci"."id"
      LEFT JOIN "versions" AS "lv"
        ON "lv"."target_type" = \'LiveContentItem\'
        AND "lv"."target_id" = "lci"."id"
      LEFT JOIN "versions" AS "dv"
        ON "dv"."target_type" = \'DraftContentItem\'
        AND "dv"."target_id" = "dci"."id"
    '
    say_with_time "Creating lock versions for content items" do
      ActiveRecord::Base.connection.execute(lock_version_for_content_items_sql)
    end

    puts "LockVersions: #{LockVersion.count}, Content Items: #{ContentItem.count}"

    lock_version_for_link_sets_sql = '
      INSERT INTO "lock_versions" (
                  "target_id",
                  "target_type",
                  "number",
                  "created_at",
                  "updated_at"
      )
      SELECT "ls"."id", "v"."target_type", "v"."number", NOW(), NOW()
      FROM "versions" "v"
      JOIN "link_sets" "ls" ON
        "v"."target_type" = \'LinkSet\' AND
        "v"."target_id" = "ls"."id"
    '
    say_with_time "Creating lock versions for link sets" do
      ActiveRecord::Base.connection.execute(lock_version_for_link_sets_sql)
    end

    puts "LockVersions: #{LockVersion.count}, Link Sets: #{LinkSet.count}"

    access_limit_sql = '
      UPDATE "access_limits" SET
        "target_type" = NULL,
        "target_id" = NULL,
        "content_item_id" = "subquery"."id"
      FROM (
        SELECT "id", "draft_content_item_id" FROM "content_items"
      ) AS "subquery"
      WHERE "subquery"."draft_content_item_id" = "access_limits"."target_id"
      AND "access_limits"."target_type" = \'DraftContentItem\'
    '

    say_with_time "Updating access limits" do
      ActiveRecord::Base.connection.execute(access_limit_sql)
    end

    puts "AccessLimit: #{AccessLimit.count}"

    user_facing_versions_for_live_items_sql = '
      INSERT INTO "user_facing_versions" (
                  "content_item_id",
                  "number",
                  "created_at",
                  "updated_at"
      )
      SELECT "content_items"."id", 1, NOW(), NOW() FROM "content_items"
      JOIN "live_content_items" on "live_content_items"."id" = "content_items"."live_content_item_id"
    '

    say_with_time "Creating user facing versions for live items" do
      ActiveRecord::Base.connection.execute(user_facing_versions_for_live_items_sql)
    end

    puts "UserFacingVersion: #{UserFacingVersion.count}"

    user_facing_versions_for_draft_items_sql = '
      INSERT INTO "user_facing_versions" (
                  "content_item_id",
                  "number",
                  "created_at",
                  "updated_at"
      )
      SELECT
        "content_items"."id",

        CASE
          WHEN "live_content_items"."id" IS NULL
             THEN 1
             ELSE 2
        END AS number,

        NOW(),
        NOW()
      FROM "content_items"
      JOIN "draft_content_items" on "draft_content_items"."id" = "content_items"."draft_content_item_id"
      LEFT JOIN "live_content_items" on "live_content_items"."draft_content_item_id" = "draft_content_items"."id"
    '

    say_with_time "Creating user facing versions for draft items" do
      ActiveRecord::Base.connection.execute(user_facing_versions_for_draft_items_sql)
    end

    puts "UserFacingVersion: #{UserFacingVersion.count}"

    # Commented out as source data needs sanitising
    #
    # add_index :access_limits, :content_item_id, unique: true
    # change_column_null :access_limits, :content_item_id, false
  end

  def down
    drop_table :content_items
    drop_table :translations
    drop_table :locations
    drop_table :states
    drop_table :user_facing_versions
    drop_table :lock_versions
    remove_column :access_limits, :content_item_id
  end
end
