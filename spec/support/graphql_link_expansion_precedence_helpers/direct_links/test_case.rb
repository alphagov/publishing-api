module GraphqlLinkExpansionPrecedenceHelpers
  module DirectLinks
    class TestCase
      include FactoryBot::Syntax::Methods

      def initialize(
        root_locale:,
        linked_editions:,
        target_content_ids_differ:
      )
        @root_locale = root_locale
        @linked_editions_input = linked_editions
        @target_content_ids_differ = target_content_ids_differ
      end

      def content_store_titles
        @content_store_titles ||= Presenters::Queries::ExpandedLinkSet
          .by_edition(source_edition, with_drafts: false)
          .links
          .fetch(link_type.to_sym, [])
          .map { it[:title] }
      end

      def graphql_titles
        @graphql_titles ||= GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            Sources::LinkedToEditionsSource,
            content_store: "live",
            locale: root_locale,
          ).request([source_edition, link_type])

          request.load.map(&:title)
        end
      end

      def invalid_edition_and_valid_link_set_linked_editions?
        return false unless linked_editions.key?(:edition)

        !valid_linked_edition_of_kind?(:edition) &&
          valid_linked_edition_of_kind?(:link_set)
      end

      def description
        "includes the correct linked editions with candidates: #{linked_editions_input.inspect}"
      end

      def source_edition_locale_description
        "when the source edition's locale is \"#{root_locale}\""
      end

    private

      attr_reader :root_locale, :linked_editions_input, :target_content_ids_differ

      def source_edition
        @source_edition ||= create(
          :live_edition,
          document: create(:document, locale: root_locale),
          edition_links: linked_editions
            .fetch(:edition, [])
            .uniq(&:content_id)
            .map { { link_type:, target_content_id: it.content_id } },
          link_set_links: linked_editions
            .fetch(:link_set, [])
            .uniq(&:content_id)
            .map { { link_type:, target_content_id: it.content_id } },
        )
      end

      def linked_editions
        @linked_editions ||= linked_editions_input
          .group_by { it[:link_kind].to_sym }
          .transform_values do |linked_editions_for_link_kind|
            linked_editions_for_link_kind.map do |linked_edition|
              TestLinkedEditionFactory.new(
                **linked_edition.except(:permitted_unpublished_link_type),
                content_id: target_content_id,
              ).call
            end
          end
      end

      def target_content_id
        if target_content_ids_differ
          SecureRandom.uuid
        else
          @target_content_id ||= SecureRandom.uuid
        end
      end

      def link_type
        @link_type ||= if linked_editions_input.any? { it[:permitted_unpublished_link_type] }
                         Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
                       else
                         "ordered_related_items"
                       end
      end

      def valid_linked_edition_of_kind?(kind)
        return false unless linked_editions.key?(kind)

        linked_editions[kind].any? do |edition|
          next if Edition::NON_RENDERABLE_FORMATS.include?(edition.document_type)
          next unless [Edition::DEFAULT_LOCALE, root_locale].include?(edition.locale)

          if edition.unpublished?
            next unless edition.withdrawn?
            next unless Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(link_type)
          end

          true
        end
      end
    end
  end
end
