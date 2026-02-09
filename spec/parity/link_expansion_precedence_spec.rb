module LinkExpansionPrecedenceTestHelpers
  class TestLinkedEditionFactory
    def initialize(
      state:,
      renderable_document_type:,
      locale:,
      withdrawal:,
      link_kind:,
      content_id:
    )
      @state = state
      @renderable_document_type = renderable_document_type
      @locale = locale
      @withdrawal = withdrawal
      @link_kind = link_kind
      @content_id = content_id
    end

    def call
      Edition.find_by(state:, document:) ||
        FactoryBot.create(
          state == "draft" ? :edition : :live_edition,
          title: "edition #{Edition.count} (#{link_kind})",
          state:,
          document_type:,
          document:,
        ).tap do
          if state == "unpublished"
            FactoryBot.create(:unpublishing, edition: it, type: unpublishing_type)
          end
        end
    end

  private

    attr_reader :state, :renderable_document_type, :locale, :withdrawal, :link_kind, :content_id

    def document_type
      if renderable_document_type
        (
          GovukSchemas::DocumentTypes.valid_document_types -
          Edition::NON_RENDERABLE_FORMATS
        ).sample
      else
        Edition::NON_RENDERABLE_FORMATS.sample
      end
    end

    def document
      Document.find_by(content_id:, locale:) ||
        FactoryBot.create(:document, content_id:, locale:)
    end

    def unpublishing_type
      return "withdrawal" if withdrawal

      Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
    end
  end

  class TestCase
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

    def content_store_result
      Presenters::Queries::ExpandedLinkSet
        .by_edition(source_edition, with_drafts:)
        .links
        .fetch(link_type.to_sym, [])
    end

    def graphql_result
      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          Sources::LinkedToEditionsSource,
          with_drafts:,
          locale: root_locale,
        ).request([source_edition, link_type])

        request.load
      end
    end

    def description
      "is consistent with linked editions: #{linked_editions_input.inspect}"
    end

    def with_drafts_description
      "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
    end

    def source_edition_locale_description
      "when the source edition's locale is #{root_locale}"
    end

  private

    attr_reader :with_drafts, :root_locale, :linked_editions_input, :target_content_ids_differ

    def source_edition
      @source_edition ||= FactoryBot.create(
        :live_edition,
        document: FactoryBot.create(:document, locale: root_locale),
        edition_links: linked_editions
          .fetch(:edition, [])
          .uniq { it[:target_content_id] }
          .map { { link_type:, target_content_id: it.content_id } },
        link_set_links: linked_editions
          .fetch(:link_set, [])
          .uniq { it[:target_content_id] }
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
  end

  class TestCaseFactory
    class << self
      def all(target_content_ids_differ:)
        query_values = [
          { with_drafts: true, root_locale: Edition::DEFAULT_LOCALE },
          { with_drafts: true, root_locale: "fr" },
          { with_drafts: false, root_locale: Edition::DEFAULT_LOCALE },
          { with_drafts: false, root_locale: "fr" },
        ]

        link_kind_values = %w[link_set edition]

        # state, withdawal, permitted unpublished link type
        state_values = [
          ["draft", nil, nil],
          ["published", nil, nil],
          ["unpublished", true, true],
          ["unpublished", true, false],
          ["unpublished", false, true],
          ["unpublished", false, false],
        ]

        renderable_document_type_values = [false, true]
        locale_values = [Edition::DEFAULT_LOCALE, "fr", "hu"]

        edition_values = link_kind_values.product(
          state_values,
          renderable_document_type_values,
          locale_values,
        ).map do
          {
            link_kind: _1,
            state: _2[0],
            withdrawal: _2[1],
            permitted_unpublished_link_type: _2[2],
            renderable_document_type: _3,
            locale: _4,
          }
        end

        edition_pairs = edition_values.combination(2).to_a

        query_values
          .product(edition_pairs)
          .map { { **_1, linked_editions: _2 } }
          .reject { |test_case|
            [
              redundant_locale(test_case),
              mismatching_link_type(test_case),
              *unless target_content_ids_differ
                 [
                   document_with_two_editions_in_live_content_store(test_case),
                   single_edition_with_mismatching_document_type(test_case)
                 ]
              end
            ].any?
          }
          .map { TestCase.new(**it, target_content_ids_differ:) }
      end

    private

      def fields_equal(a, b, *fields) # rubocop:disable Naming/MethodParameterName
        fields.all? { a[it] == b[it] }
      end

      # we only need to test one non-default/fallback non-root-matching locale
      def redundant_locale(test_case)
        test_case[:root_locale] == Edition::DEFAULT_LOCALE &&
          test_case[:linked_editions].any? { it[:locale] == "hu" }
      end

      # the link type must be the same for two targets to compete, so we
      # filter out cases where we have both true and false for the permitted
      # unpublished link type (from which we derive the link type)
      def mismatching_link_type(test_case)
        test_case[:linked_editions]
        .map { it[:permitted_unpublished_link_type] }
        .compact.uniq.size > 1
      end

      # given the target content ID is the same, the document must be the same if
      # the locale is the same. in such cases, we can't have two editions in the
      # same content store
      def document_with_two_editions_in_live_content_store(test_case)
        fields_equal(*test_case[:linked_editions], :locale) &&
          test_case[:linked_editions]
            .map { it[:state] }
            .sort == %w[published unpublished]
      end

      # given the target content ID is the same, the edition must be the same if
      # the state and locale are the same. in such cases, they can't have a
      # different document type
      def single_edition_with_mismatching_document_type(test_case)
        fields_equal(*test_case[:linked_editions], :state, :locale) &&
          !fields_equal(*test_case[:linked_editions], :renderable_document_type)
      end
    end
  end
end

# 4664
# puts TestCaseFactory.all.count

RSpec.describe "link expansion precedence" do
  context "when targeting the same content ID" do
    LinkExpansionPrecedenceTestHelpers::TestCaseFactory.all(target_content_ids_differ: false).each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.source_edition_locale_description do
          it test_case.description do
            aggregate_failures do
              graphql_titles = test_case.graphql_result.map(&:title)
              content_store_titles = test_case
                .content_store_result
                .map { it[:title] }

              expect(graphql_titles).to eq(content_store_titles)
              expect(test_case.content_store_result.size).to be <= 1
              expect(test_case.graphql_result.size).to be <= 1
            end
          end
        end
      end
    end
  end

  context "when targeting different content IDs" do
    LinkExpansionPrecedenceTestHelpers::TestCaseFactory.all(target_content_ids_differ: true).each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.source_edition_locale_description do
          it test_case.description do
            aggregate_failures do
              graphql_titles = test_case.graphql_result.map(&:title)
              content_store_titles = test_case
                .content_store_result
                .map { it[:title] }

              expect(graphql_titles).to eq(content_store_titles)
              expect(test_case.content_store_result.size).to be <= 1
              expect(test_case.graphql_result.size).to be <= 1
            end
          end
        end
      end
    end
  end
end
