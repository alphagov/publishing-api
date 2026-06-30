module Queries
  class ReverseLinkedToEditions
    SQL = File.read(Rails.root.join("app/queries/sql/reverse_linked_to_editions.sql"))

    def initialize(locale:, with_drafts: false)
      @primary_locale = locale
      @secondary_locale = Edition::DEFAULT_LOCALE
      @with_drafts = with_drafts
    end

    # Returns a Hash with one [content_id, link_type] key per input pair, in
    # input order, each seeded with []. Sources::ReverseLinkedToEditionsSource
    # relies on the ordering to satisfy GraphQL::Dataloader's fetch contract
    # via .values.
    def call(editions_and_link_types)
      link_types_map = {}
      query_input = []
      editions_and_link_types.each do |edition, link_type|
        query_input.push({ content_id: edition.content_id, link_type: })
        link_types_map[[edition.content_id, link_type]] = []
      end

      return link_types_map if query_input.empty?

      sql_params = {
        query_input: query_input.to_json,
        query_input_count: query_input.count,
        primary_locale: @primary_locale,
        secondary_locale: @secondary_locale,
        permitted_not_unpublished_states: @with_drafts ? %i[draft published] : %i[published],
        unpublished_link_types: Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        non_renderable_formats: Edition::NON_RENDERABLE_FORMATS,
      }
      all_editions = Edition.find_by_sql([SQL, sql_params])
      all_editions.each(&:strict_loading!)
      all_editions.each_with_object(link_types_map) do |edition, hash|
        key = [edition.target_content_id, edition.link_type]
        hash[key] << edition unless hash[key].include?(edition)
      end
    end
  end
end
