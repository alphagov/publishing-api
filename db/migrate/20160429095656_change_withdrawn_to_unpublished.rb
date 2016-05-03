class ChangeWithdrawnToUnpublished < ActiveRecord::Migration
  def up
    create_table :unpublishings do |t|
      t.references :content_item, null: false
      t.string :type, null: false
      t.string :explanation
      t.string :alternative_url
      t.timestamps
    end

    add_index :unpublishings, :content_item_id
    add_index :unpublishings, [:content_item_id, :type]

    withdrawn_content_items = ContentItemFilter.filter(state: "withdrawn")

    puts "Updating #{withdrawn_content_items.count} withdrawn content items"

    withdrawn_content_items.find_each do |withdrawn_ci|
      user_facing_version = UserFacingVersion.find_by(content_item: withdrawn_ci)
      location = Location.find_by(content_item: withdrawn_ci)
      translation = Translation.find_by(content_item: withdrawn_ci)

      puts "Creating unpublishing for [ #{user_facing_version.number} | withdrawn | #{location.base_path} | #{translation.locale} ]"

      Unpublishing.create!(
        content_item: withdrawn_ci,
        type: "substitute",
        explanation: "Automatically unpublished to make way for another content item",
      )
    end

    puts "Renaming 'withdrawn' to 'unpublished'"
    State.where(name: "withdrawn").update_all(name: "unpublished")
  end

  def down
    drop_table :unpublishings
    State.where(name: "unpublished").update_all(name: "withdrawn")
  end
end
