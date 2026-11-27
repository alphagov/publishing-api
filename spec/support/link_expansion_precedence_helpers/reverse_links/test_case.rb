module LinkExpansionPrecedenceHelpers
  module ReverseLinks
    class TestCase
      include FactoryBot::Syntax::Methods

      STATE_PRECEDENCE = %w[published unpublished].freeze

      def initialize(
        with_drafts:,
        root_locale:,
        source_editions:,
        source_content_ids_differ:
      )
        @with_drafts = with_drafts
        @root_locale = root_locale
        @source_editions_input = source_editions
        @source_content_ids_differ = source_content_ids_differ
      end

      def content_store_titles
        @content_store_titles ||= begin
          source_editions

          Presenters::Queries::ExpandedLinkSet
            .by_edition(linked_edition, with_drafts:)
            .links
            .fetch(ExpansionRules.reverse_link_type(link_type), [])
            .map { it[:title] }
        end
      end

      def expected_titles
        @expected_titles ||= source_editions_with_winning_links
          .map(&:content_id)
          .uniq
          .filter_map { preferred_edition(it)&.title }
      end

      def description
        "includes the correct reverse-linked (source) editions with candidates: #{source_editions_input.inspect}"
      end

      def linked_edition_locale_description
        "when the linked (root) edition's locale is \"#{root_locale}\""
      end

      def with_drafts_description
        "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
      end

    private

      attr_reader :with_drafts, :root_locale, :source_editions_input, :source_content_ids_differ

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

      def source_editions_with_winning_links
        root_locale_edition_linking_editions = source_editions
          .fetch(:edition, [])
          .select { it.locale == root_locale }

        if root_locale_edition_linking_editions.any?
          root_locale_edition_linking_editions
        else
          source_editions.fetch(:link_set, [])
        end
      end

      def preferred_edition(content_id)
        source_editions.values.flatten.uniq
          .select { it.content_id == content_id && valid_edition?(it) }
          .min_by do |edition|
            [
              STATE_PRECEDENCE.index(edition.state),
              [root_locale, Edition::DEFAULT_LOCALE].uniq.index(edition.locale),
            ]
          end
      end

      def valid_edition?(edition)
        return false if Edition::NON_RENDERABLE_FORMATS.include?(edition.document_type)
        return false unless [Edition::DEFAULT_LOCALE, root_locale].include?(edition.locale)
        return false if edition.draft? && !with_drafts

        if edition.unpublished?
          return false unless edition.withdrawn?
          return false unless Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(link_type)
        end

        true
      end
    end
  end
end
