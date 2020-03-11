class PopulateContentStoreField < ActiveRecord::Migration[5.0]
  def up
    execute "UPDATE content_items SET content_store = (
              SELECT
              CASE
                WHEN state = 'draft' THEN 'draft'
                WHEN state IN ('published', 'unpublished')
                AND (unpublishings.type IS NULL OR unpublishings.type != 'substitute') THEN 'live'
                ELSE NULL
              END
              FROM content_items c
              LEFT JOIN
                unpublishings ON state = 'unpublished'
                AND
                unpublishings.content_item_id = c.id
              WHERE c.id = content_items.id
             )"
  end

  def down; end
end
