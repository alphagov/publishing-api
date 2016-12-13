module DataHygiene
  module DuplicateContentItem
    class StateForLocale
      include DuplicateContentItem::ResultsHelper

      def has_duplicates?
        number_of_duplicates > 0
      end

      def number_of_duplicates
        results[:number_of_duplicates]
      end

      def results
        @results ||= build_results
      end

      def log
        return unless has_duplicates?
        message = "#{results[:distinct_content_item_ids]} content items with state for locale conflicts"
        Airbrake.notify(
          DuplicateContentItem::DuplicateStateForLocaleError.new(message),
          parameters: results
        )
      end

    private

      def build_results
        query_results = ActiveRecord::Base.connection.execute(sql)
        duplicates = query_results.map do |row|
          row.symbolize_keys.merge(
            content_items: content_items_string_to_hash(row["content_items"])
          )
        end
        content_ids = content_ids_from_duplicates(duplicates)
        content_item_ids = content_item_ids_from_duplicates(duplicates)
        {
          distinct_content_ids: content_ids.count,
          content_ids: content_ids,
          distinct_content_item_ids: content_item_ids.count,
          content_item_ids: content_item_ids,
          number_of_duplicates: duplicates.count,
          duplicates: duplicates
        }
      end

      def sql
        <<-SQL
          SELECT content_items.content_id,
            content_items.locale,
            CASE content_items.state
              WHEN 'draft' THEN 'draft' ELSE 'live'
            END AS content_store,
            ARRAY_AGG(
              ROW(content_items.id, content_items.updated_at)
              ORDER BY content_items.updated_at DESC
            ) as content_items
          FROM content_items
          WHERE content_items.state IN ('draft', 'published', 'unpublished')
          GROUP BY content_items.content_id, content_items.locale, content_store
          HAVING COUNT(*) > 1
        SQL
      end
    end
  end
end
