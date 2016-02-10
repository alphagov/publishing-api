class DraftContentItem < ActiveRecord::Base; end
class LiveContentItem < ActiveRecord::Base; end

class ExtractSemanticVersion < ActiveRecord::Migration
  def up
    create_table :locations do |t|
      t.references :content_item
      t.string :base_path

      t.timestamps null: false
    end
    add_index :locations, [:content_item_id, :base_path]

    create_table :translations do |t|
      t.references :content_item
      t.string :locale

      t.timestamps null: false
    end
    add_index :translations, [:content_item_id, :locale]

    create_table :states do |t|
      t.references :content_item
      t.string :name

      t.timestamps null: false
    end
    add_index :states, [:content_item_id, :name]

    create_table :semantic_versions do |t|
      t.references :content_item
      t.integer :number, default: 0, null: false

      t.timestamps null: false
    end
    add_index :semantic_versions, [:content_item_id, :number]

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
      t.json     "need_ids",             default: []
      t.string   "update_type"
      t.string   "phase",                default: "live"
      t.string   "analytics_identifier"
      t.json     "description",          default: {"value"=>nil}

      t.timestamps null: false
    end

    # No longer polymorphic
    add_column :access_limits, :content_item_id, :integer
    change_column_null :access_limits, :target_id, true
    change_column_null :access_limits, :target_type, true

    content_items = DraftContentItem.all.to_a + LiveContentItem.all.to_a

    grouped_content_items = content_items.group_by(&:content_id)
    group_count = grouped_content_items.count

    grouped_content_items.each.with_index(1) do |(content_id, content_items), index|
      lives, drafts = content_items.partition { |ci| ci.is_a?(LiveContentItem) }
      live = lives.first
      draft = drafts.first

      unwanted_fields = [
        "id",
        "old_description",
        "draft_content_item_id",
        "access_limited",
        "locale",
        "base_path",
      ]

      if live
        new_live = ContentItem.create!(live.attributes.except(*unwanted_fields))

        Translation.create!(
          locale: live.locale,
          content_item: new_live,
        )

        Location.create!(
          base_path: live.base_path,
          content_item: new_live,
        )

        State.create!(
          name: "published",
          content_item: new_live,
        )

        if (version = Version.find_by(target: live))
          version.update_attributes(target: new_live)
        end
      end

      if draft
        new_draft = ContentItem.create!(draft.attributes.except(*unwanted_fields))

        Translation.create!(
          locale: draft.locale,
          content_item: new_draft,
        )

        Location.create!(
          base_path: draft.base_path,
          content_item: new_draft,
        )

        State.create!(
          name: "draft",
          content_item: new_draft,
        )


        if (access_limit = AccessLimit.find_by(target: draft))
          access_limit.update_attributes!(
            target: nil,
            content_item: new_draft,
          )
        end

        if (version = Version.find_by(target: draft))
          version.target = new_draft
          version.save!(validate: false)
        end
      end

      print_progress(index, group_count)
    end

    puts

    add_index :access_limits, :content_item_id, unique: true
    change_column_null :access_limits, :content_item_id, false
  end

  def down
    drop_table :content_items
    drop_table :translations
    drop_table :locations
    drop_table :states
    drop_table :semantic_versions
    remove_column :access_limits, :content_item_id
  end

  def print_progress(completed, total)
    percent_complete = ((completed.to_f / total) * 100).round
    percent_remaining = 100 - percent_complete

    print "\r"
    STDOUT.flush
    print "Progress [#{"=" * percent_complete}>#{"." * percent_remaining}] (#{percent_complete}%)"
    STDOUT.flush
  end
end
