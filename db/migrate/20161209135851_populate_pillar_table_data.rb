class PopulatePillarTableData < ActiveRecord::Migration[5.0]
  def convert_from_pillar(pillar_table:, pillar_column:, content_items_column:)
    execute "UPDATE content_items
             SET #{content_items_column} = #{pillar_table}.#{pillar_column}
             FROM #{pillar_table}
             WHERE #{pillar_table}.content_item_id = content_items.id
             AND (
              (content_items.#{content_items_column} IS NULL AND #{pillar_table}.#{pillar_column} IS NOT NULL)
              OR
              content_items.#{content_items_column} != #{pillar_table}.#{pillar_column}
             )"
  end

  def convert_back_to_pillar(pillar_table:, pillar_column:, content_items_column:)
    execute "UPDATE #{pillar_table}
             SET #{pillar_column} = content_items.#{content_items_column}
             FROM content_items
             WHERE #{pillar_table}.content_item_id = content_items.id
             AND (
              (content_items.#{content_items_column} IS NOT NULL AND #{pillar_table}.#{pillar_column} IS NULL)
              OR
              content_items.#{content_items_column} != #{pillar_table}.#{pillar_column}
             )"
  end

  def up
    # Run updates without a lock to keep the Publishing API running while this
    # migration occurs
    execute "UPDATE content_items SET state = (
              SELECT states.name FROM states
              WHERE states.content_item_id = content_items.id
            )"

    execute "UPDATE content_items SET locale = (
              SELECT translations.locale FROM translations
              WHERE translations.content_item_id = content_items.id
            )"

    execute "UPDATE content_items SET user_facing_version = (
              SELECT user_facing_versions.number FROM user_facing_versions
              WHERE user_facing_versions.content_item_id = content_items.id
            )"

    execute "UPDATE content_items SET base_path = (
              SELECT locations.base_path FROM locations
              WHERE locations.content_item_id = content_items.id
            )"

    # Lock the content_items table to catch anything that has changed since we
    # made our update
    execute "LOCK TABLE content_items"

    convert_from_pillar(
      pillar_table: "states",
      pillar_column: "name",
      content_items_column: "state",
    )
    convert_from_pillar(
      pillar_table: "translations",
      pillar_column: "locale",
      content_items_column: "locale",
    )
    convert_from_pillar(
      pillar_table: "user_facing_versions",
      pillar_column: "number",
      content_items_column: "user_facing_version",
    )
    convert_from_pillar(
      pillar_table: "locations",
      pillar_column: "base_path",
      content_items_column: "base_path",
    )
  end

  def down
    execute "LOCK TABLE content_items"

    convert_back_to_pillar(
      pillar_table: "states",
      pillar_column: "name",
      content_items_column: "state",
    )
    convert_back_to_pillar(
      pillar_table: "translations",
      pillar_column: "locale",
      content_items_column: "locale",
    )
    convert_back_to_pillar(
      pillar_table: "user_facing_versions",
      pillar_column: "number",
      content_items_column: "user_facing_version",
    )
    convert_back_to_pillar(
      pillar_table: "locations",
      pillar_column: "base_path",
      content_items_column: "base_path",
    )
  end
end
