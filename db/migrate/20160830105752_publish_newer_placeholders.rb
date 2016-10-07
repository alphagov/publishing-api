class PublishNewerPlaceholders < ActiveRecord::Migration
  def up
    to_publish = [
      ["c3cd8556-4a95-4c6d-ab2d-d1f6cd280d37", "en"],
      ["c8d9daa3-6e3a-4422-bde4-b85b7a54c526", "en"],
      ["41d78758-1ecd-401e-99d3-2325982a6da7", "en"]
    ]

    to_publish.each do |(content_id, locale)|
      next if missing?(content_id) || already_published?(content_id, locale)
      Commands::V2::Publish.call(
        content_id: content_id,
        locale: locale,
        update_type: "minor",
      )
    end
  end

  def missing?(content_id)
    ContentItem.where(content_id: content_id).none?
  end

  def already_published?(content_id, locale)
    results = connection.execute("
      SELECT COUNT(*)
      FROM content_items
      INNER JOIN translations ON translations.content_item_id = content_items.id
      INNER JOIN states ON states.content_item_id = content_items.id
      WHERE states.name = 'published'
      AND translations.locale = #{connection.quote(locale)}
      AND content_items.content_id = #{connection.quote(content_id)}
    ")
    results[0]["count"] != "0"
  end
end
