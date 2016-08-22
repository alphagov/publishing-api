module DataHygiene
  class DuplicateContentItem
    class BasePathForState
      def has_duplicates?
        results[:duplicates].any?
      end

      def results
        @results ||= build_results
      end

      def log
        return unless has_duplicates?
        message = "#{results[:distinct_content_item_ids]} content items with base path for state conflicts"
        Airbrake.notify_or_ignore(
          DuplicateContentItem::DuplicateBasePathForStateError.new(message),
          parameters: results
        )
      end

    private

      def build_results
        query_results = ActiveRecord::Base.connection.execute(sql)
        duplicates = query_results.map do |row|
          content_ids = row["content_ids"][1...-1].split(",")
          content_items = row["content_items"].scan(/\((.+?)\)/).flatten.map do |id_time|
            id, time = id_time.split(",")
            { content_item_id: id.to_i, updated_at: Time.zone.parse(time.gsub(/\\"/, "")) }
          end
          row.symbolize_keys.merge(content_items: content_items, content_ids: content_ids)
        end
        content_ids = duplicates.inject(Set.new) { |memo, row| memo.merge(row[:content_ids]) }
        get_content_item_ids = ->(row) do
          row[:content_items].map { |pair| pair[:content_item_id] }
        end
        content_item_ids = duplicates.map(&get_content_item_ids).flatten.uniq
        {
          distinct_content_ids: content_ids.count,
          content_ids: content_ids.to_a,
          distinct_content_item_ids: content_item_ids.count,
          content_item_ids: content_item_ids,
          duplicates: duplicates
        }
      end

      def sql
        <<-SQL
          SELECT locations.base_path,
            CASE states.name
              WHEN 'draft'
              THEN 'draft'
              ELSE 'live'
            END AS content_store,
            ARRAY_AGG(DISTINCT content_items.content_id) as content_ids,
            ARRAY_AGG(
              ROW(content_items.id, content_items.updated_at)
              ORDER BY content_items.updated_at DESC
            ) as content_items
          FROM content_items
          INNER JOIN locations
            ON locations.content_item_id = content_items.id
          INNER JOIN states
            ON states.content_item_id = content_items.id
          LEFT JOIN unpublishings
            ON states.name = 'unpublished'
            AND unpublishings.content_item_id = content_items.id
          WHERE locations.base_path IS NOT NULL
            AND states.name IN ('draft', 'published', 'unpublished')
            AND (unpublishings.type IS NULL OR unpublishings.type != 'substitute')
          GROUP BY locations.base_path, content_store
          HAVING COUNT(*) > 1
        SQL
      end
    end
  end
end
