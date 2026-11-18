module LinkExpansionPrecedenceHelpers
  module DirectLinks
    class TestCase
      include FactoryBot::Syntax::Methods

      STATE_PRECEDENCE = %w[published unpublished].freeze

      def initialize(
        with_drafts:,
        root_locale:,
        linked_editions:,
        target_content_ids_differ:
      )
        @with_drafts = with_drafts
        @root_locale = root_locale
        @linked_editions_input = linked_editions
        @target_content_ids_differ = target_content_ids_differ
      end

      def content_store_titles
        @content_store_titles ||= Presenters::Queries::ExpandedLinkSet
          .by_edition(source_edition, with_drafts:)
          .links
          .fetch(link_type.to_sym, [])
          .map { it[:title] }
      end

      def expected_titles
        @expected_titles ||= linked_editions
          .fetch(winning_link_kind)
          .map(&:content_id)
          .uniq
          .filter_map { preferred_edition(it)&.title }
      end

      def description
        "includes the correct linked editions with candidates: #{linked_editions_input.inspect}"
      end

      def source_edition_locale_description
        "when the source edition's locale is \"#{root_locale}\""
      end

      def with_drafts_description
        "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
      end

    private

      attr_reader :with_drafts, :root_locale, :linked_editions_input, :target_content_ids_differ

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

      def winning_link_kind
        linked_editions.key?(:edition) ? :edition : :link_set
      end

      def preferred_edition(content_id)
        linked_editions.values.flatten.uniq
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
