module Presenters
  module Queries
    class GroupedContentAndLinks
      def initialize(results)
        self.results = results
      end

      def present
        {
          "last_seen_content_id" => last_seen_content_id,
          "results" => present_results,
        }
      end

    private

      attr_accessor :results

      def present_results
        results.map { |result| present_result(result) }
      end

      def last_seen_content_id
        return if results.empty?

        results.last["content_id"]
      end

      def present_result(query_result)
        {
          "content_id" => query_result["content_id"],
          "content_items" => present_content_items(query_result["content_items"]),
          "links" => present_links(query_result["links"])
        }
      end

      def present_content_items(content_items)
        content_items.map { |content_item| present_content_item(content_item) }
      end

      def present_content_item(content_item)
        content_item.slice(
          "locale",
          "base_path",
          "publishing_app",
          "schema_name",
          "document_type",
          "user_facing_version",
          "state"
        )
      end

      # Links is an array of individual link rows
      # So we need to group them by type
      def present_links(links)
        groups = links.group_by { |link| link.fetch("link_type") }

        groups.each_with_object({}) do |(link_type, type_links), links_hash|
          links_hash[link_type] = type_links.map do |link|
            link.fetch("target_content_id")
          end
        end
      end
    end
  end
end
