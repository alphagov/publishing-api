module Queries
  class GetGroupedContentAndLinks
    PAGE_SIZE = 10
    MAX_PAGE_SIZE = 1000

    include ActiveModel::Validations

    attr_accessor :last_seen_content_id, :page_size

    validates_numericality_of :page_size, less_than_or_equal_to: MAX_PAGE_SIZE, greater_than: 0

    def initialize(last_seen_content_id: nil, page_size: nil)
      @last_seen_content_id = last_seen_content_id
      @page_size = page_size || PAGE_SIZE
    end

    # Returns an array of hashes where each hash contains a content_id, an
    # array of content item rows, and an array of link rows.
    #
    # The pagination works differently to other requests because content ids
    # are not generated in any kind of order. When paging through the results
    # we need to be sure of:
    #
    # - not missing a content_id that already existed when we started the
    #   first page
    #
    # - not seeing any content_id twice
    #
    # - seeing complete and consistent data for each content_id returned
    def call
      content_ids = query_content_ids_for_page(
        last_seen_content_id: last_seen_content_id,
        page_size: page_size
      )

      group_results(content_ids, content_results(content_ids), link_set_results(content_ids))
    end

  private

    def query_content_ids_for_page(last_seen_content_id:, page_size:)
      groups = ContentItem.group(:content_id)

      if last_seen_content_id.nil?
        page = groups
          .limit(page_size)
          .order(:content_id)
      else
        page = groups
          .having("content_id > ?", last_seen_content_id)
          .limit(page_size)
          .order(:content_id)
      end

      page.pluck(:content_id)
    end

    def group_results(content_ids, content_results, link_set_results)
      grouped_content_items = group_by_content_id(content_results)
      grouped_links = group_by_content_id(link_set_results)

      content_ids.map do |content_id|
        {
          "content_id" => content_id,
          "content_items" => grouped_content_items[content_id],
          "links" => grouped_links[content_id] || []
        }
      end
    end

    def group_by_content_id(results)
      results.group_by { |item| item["content_id"] }
    end

    def content_results(content_ids)
      return [] if content_ids.empty?

      query = <<-SQL
        SELECT
          content_items.content_id,
          content_items.id AS content_item_id,
          translations.locale,
          locations.base_path,
          states.name AS state,
          user_facing_versions.number AS user_facing_version,
          content_items.publishing_app,
          content_items.format
        FROM content_items
        JOIN translations
          ON translations.content_item_id = content_items.id
        JOIN locations
          ON locations.content_item_id = content_items.id
        JOIN states
          ON states.content_item_id = content_items.id
        JOIN user_facing_versions
          ON user_facing_versions.content_item_id = content_items.id
        WHERE
          content_items.content_id IN (#{sql_value_placeholders(content_ids.size)})
        ORDER BY
          content_items.updated_at DESC
      SQL

      ActiveRecord::Base.connection.raw_connection.exec(query, content_ids)
    end

    def link_set_results(content_ids)
      return [] if content_ids.empty?

      query = <<-SQL
        SELECT
          link_sets.content_id,
          links.link_type,
          links.target_content_id
        FROM link_sets
        JOIN links
          ON link_sets.id = links.link_set_id
        WHERE
          link_sets.content_id IN (#{sql_value_placeholders(content_ids.size)})
      SQL

      ActiveRecord::Base.connection.raw_connection.exec(query, content_ids)
    end

    def sql_value_placeholders(number)
      (1).upto(number).map { |i| "$#{i}" }.join(',')
    end
  end
end
