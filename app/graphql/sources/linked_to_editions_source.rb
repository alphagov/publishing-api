module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    SQL = File.read(Rails.root.join("app/graphql/sources/queries/linked_to_editions.sql"))

    # rubocop:disable Lint/MissingSuper
    def initialize(locale:, with_drafts: false)
      @primary_locale = locale
      @secondary_locale = Edition::DEFAULT_LOCALE
      @with_drafts = with_drafts
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      link_types_map = {}
      query_input = []
      editions_and_link_types.each do |edition, link_type|
        query_input.push({ edition_id: edition.id, content_id: edition.content_id, link_type: })
        link_types_map[[edition.content_id, link_type]] = []
      end

      sql_params = {
        query_input: query_input.to_json,
        query_input_count: query_input.count,
        primary_locale: @primary_locale,
        secondary_locale: @secondary_locale,
        state_unless_withdrawn: @with_drafts ? %i[draft published] : %i[published],
        unpublished_link_types: Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        non_renderable_formats: Edition::NON_RENDERABLE_FORMATS,
      }
      all_editions = Edition.find_by_sql([SQL, sql_params])
      all_editions.each(&:strict_loading!)
      all_editions.each_with_object(link_types_map) { |edition, hash|
        unless hash[[edition.source_content_id, edition.link_type]].include?(edition)
          hash[[edition.source_content_id, edition.link_type]] << edition
        end
      }.values
    end
  end
end
