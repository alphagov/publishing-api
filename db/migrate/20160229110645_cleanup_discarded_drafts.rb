class CleanupDiscardedDrafts < ActiveRecord::Migration
  def change
    content_items_without_locations = ContentItem
      .joins("LEFT JOIN locations ON locations.content_item_id = content_items.id")
      .where("locations.id IS NULL")

    content_items_without_states = ContentItem
      .joins("LEFT JOIN states ON states.content_item_id = content_items.id")
      .where("states.id IS NULL")

    content_items_without_user_facing_versions = ContentItem
      .joins("LEFT JOIN user_facing_versions ON user_facing_versions.content_item_id = content_items.id")
      .where("user_facing_versions.id IS NULL")

    content_items_without_translations = ContentItem
      .joins("LEFT JOIN translations ON translations.content_item_id = content_items.id")
      .where("translations.id IS NULL")

    content_items_to_delete = [
      content_items_without_locations,
      content_items_without_states,
      content_items_without_user_facing_versions,
      content_items_without_translations,
    ].flatten.uniq

    content_items_to_delete.each do |content_item|
      puts "Checking that there are no remaining supporting objects"
      location = Location.find_by(content_item_id: content_item.id)
      state = State.find_by(content_item_id: content_item.id)
      user_facing_version = UserFacingVersion.find_by(content_item_id: content_item.id)
      translation = Translation.find_by(content_item_id: content_item.id)

      if [location, state, user_facing_version, translation].any?(&:present?)
        puts "Not destroying content_item #{content_item.id}"
        puts "Location: #{location.inspect}"
        puts "State: #{state.inspect}"
        puts "UserFacingVersion: #{user_facing_version.inspect}"
        puts "Translation: #{translation.inspect}"
      else
        puts "Deleting content_item #{content_item.id}"
        content_item.destroy
      end
    end
  end
end
