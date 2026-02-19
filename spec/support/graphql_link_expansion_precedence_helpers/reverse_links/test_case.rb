module GraphqlLinkExpansionPrecedenceHelpers
  module ReverseLinks
    class TestCase
      include FactoryBot::Syntax::Methods

      def initialize(
        root_locale:,
        source_editions:,
        source_content_ids_differ:
      )
        @root_locale = root_locale
        @source_editions_input = source_editions
        @source_content_ids_differ = source_content_ids_differ
      end

      def content_store_result
        @content_store_result ||= begin
          source_editions

          Presenters::Queries::ExpandedLinkSet
            .by_edition(linked_edition, with_drafts: false)
            .links
            .fetch(ExpansionRules.reverse_link_type(link_type), [])
        end
      end

      def graphql_result
        @graphql_result ||= begin
          source_editions

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              Sources::ReverseLinkedToEditionsSource,
              content_store: "live",
              locale: root_locale,
            ).request([linked_edition, link_type])

            request.load
          end
        end
      end

      def content_store_titles
        @content_store_titles ||= content_store_result.map { it[:title] }
      end

      def graphql_titles
        @graphql_titles ||= graphql_result.map(&:title)
      end

      def invalid_edition_and_valid_link_set_linking_source_editions?
        return false unless source_editions.key?(:edition)

        !valid_source_edition_of_kind?(:edition) &&
          valid_source_edition_of_kind?(:link_set)
      end

      def invalid_root_locale_and_valid_default_locale_edition_linking_editions?
        edition_linking_source_edition_of_locale?(root_locale) &&
          !valid_edition_linking_source_edition_of_locale?(root_locale) &&
          valid_edition_linking_source_edition_of_locale?(Edition::DEFAULT_LOCALE)
      end

      def valid_edition_and_link_set_linking_editions?
        valid_source_edition_of_kind?(:edition) &&
          valid_source_edition_of_kind?(:link_set)
      end

      def valid_published_default_locale_and_unpublished_differing_root_locale_edition_linking_editions?
        return false if root_locale == Edition::DEFAULT_LOCALE

        return false unless source_editions[:edition]&.any? do
          valid_edition?(it) &&
            it.state == "unpublished" &&
            it.locale == root_locale
        end

        source_editions[:edition].any? do
          valid_edition?(it) &&
            it.state == "published" &&
            it.locale == Edition::DEFAULT_LOCALE
        end
      end

      def description
        "includes the correct reverse-linked (source) editions with candidates: #{source_editions_input.inspect}"
      end

      def linked_edition_locale_description
        "when the linked (root) edition's locale is \"#{root_locale}\""
      end

    private

      attr_reader :root_locale, :source_editions_input, :source_content_ids_differ

      def linked_edition
        @linked_edition ||= create(
          :live_edition,
          document: create(:document, locale: root_locale),
        )
      end

      def source_editions
        @source_editions ||= source_editions_input
          .group_by { it[:link_kind].to_sym }
          .transform_values { |source_editions_for_link_kind|
            source_editions_for_link_kind.map do |source_edition|
              TestSourceEditionFactory.new(
                **source_edition.except(:permitted_unpublished_link_type),
                content_id: source_content_id,
              ).call
            end
          }
          .tap do
            it[:edition]&.each do |edition_linking_edition|
              create(
                :link,
                edition: edition_linking_edition,
                target_content_id: linked_edition.content_id,
                link_type:,
              )
            end

            it[:link_set]&.uniq(&:content_id)&.each do |link_set_linking_edition|
              create(
                :link_set,
                content_id: link_set_linking_edition.content_id,
                links_hash: { link_type => [linked_edition.content_id] },
              )
            end
          end
      end

      def source_content_id
        if source_content_ids_differ
          SecureRandom.uuid
        else
          @source_content_id ||= SecureRandom.uuid
        end
      end

      def link_type
        @link_type ||= if source_editions_input.any? { it[:permitted_unpublished_link_type] }
                         ExpansionRules::REVERSE_LINKS.keys.map(&:to_s)
                           .intersection(Link::PERMITTED_UNPUBLISHED_LINK_TYPES)
                           .sample
                       else
                         ExpansionRules::REVERSE_LINKS.keys.sample.to_s
                       end
      end

      def edition_linking_source_edition_of_locale?(locale)
        return false unless source_editions.key?(:edition)

        source_editions[:edition].any? { it.locale == locale }
      end

      def valid_source_edition_of_kind?(kind)
        return false unless source_editions.key?(kind)

        source_editions[kind].any?(&method(:valid_edition?))
      end

      def valid_edition_linking_source_edition_of_locale?(locale)
        return false unless source_editions.key?(:edition)

        source_editions[:edition]
          .filter { it.locale == locale }
          .any?(&method(:valid_edition?))
      end

      def valid_edition?(edition)
        return false if Edition::NON_RENDERABLE_FORMATS.include?(edition.document_type)
        return false unless [Edition::DEFAULT_LOCALE, root_locale].include?(edition.locale)

        if edition.unpublished?
          return false unless edition.withdrawn?
          return false unless Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(link_type)
        end

        true
      end
    end
  end
end
