class PopulatePillarTableData < ActiveRecord::Migration[5.0]
  def up
    execute 'UPDATE content_items SET state = (
              SELECT states.name FROM states
              WHERE states.content_item_id = content_items.id
            )'

    execute 'UPDATE content_items SET locale = (
              SELECT translations.locale FROM translations
              WHERE translations.content_item_id = content_items.id
            )'

    execute 'UPDATE content_items SET user_facing_version = (
              SELECT user_facing_versions.number FROM user_facing_versions
              WHERE user_facing_versions.content_item_id = content_items.id
            )'

    execute 'UPDATE content_items SET base_path = (
              SELECT locations.base_path FROM locations
              WHERE locations.content_item_id = content_items.id
            )'
  end

  def down; end
end
