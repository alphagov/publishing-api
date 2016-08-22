module DataHygiene
  class DuplicateContentItem
    class StateForLocale
      def has_duplicates?
        results[:duplicates].any?
      end

      def results
        @results ||= build_results
      end

      def log
        return unless has_duplicates?
        message = "#{results[:distinct_content_item_ids]} content items with state for locale conflicts"
        Airbrake.notify_or_ignore(
          DuplicateContentItem::DuplicateStateForLocaleError.new(message),
          parameters: results
        )
      end

    private

      def build_results
        query_results = ActiveRecord::Base.connection.execute(sql)
        duplicates = query_results.map do |row|
          content_items = row["content_items"].scan(/\((.+?)\)/).flatten.map do |id_time|
            id, time = id_time.split(",")
            { content_item_id: id.to_i, updated_at: Time.zone.parse(time.gsub(/\\"/, "")) }
          end
          row.symbolize_keys.merge(content_items: content_items)
        end
        content_ids = duplicates.map { |row| row[:content_id] }.uniq
        get_content_item_ids = ->(row) do
          row[:content_items].map { |pair| pair[:content_item_id] }
        end
        content_item_ids = duplicates.map(&get_content_item_ids).flatten.uniq
        {
          distinct_content_ids: content_ids.count,
          content_ids: content_ids,
          distinct_content_item_ids: content_item_ids.count,
          content_item_ids: content_item_ids,
          duplicates: duplicates
        }
      end

      def sql
        <<-SQL
          SELECT content_items.content_id,
            translations.locale,
            CASE states.name
              WHEN 'draft' THEN 'draft' ELSE 'live'
            END AS content_store,
            ARRAY_AGG(
              ROW(content_items.id, content_items.updated_at)
              ORDER BY content_items.updated_at DESC
            ) as content_items
          FROM content_items
          INNER JOIN translations
            ON translations.content_item_id = content_items.id
          INNER JOIN states
            ON states.content_item_id = content_items.id
          WHERE states.name IN ('draft', 'published', 'unpublished')
          GROUP BY content_items.content_id, translations.locale, content_store
          HAVING COUNT(*) > 1
        SQL
      end
    end
  end
end
