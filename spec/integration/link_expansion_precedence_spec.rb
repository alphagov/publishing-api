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
        draft? ? :edition : :live_edition,
        title: "edition #{Edition.count} (#{link_kind})",
        state:,
        document_type:,
        document:,
      ).tap do
        FactoryBot.create(:unpublishing, edition: it, type: unpublishing_type) if unpublished?
      end
  end

private

  attr_reader :state, :renderable_document_type, :withdrawal, :link_kind, :content_id

  def document_type
    @document_type ||= if renderable_document_type
                         renderable_types = GovukSchemas::DocumentTypes.valid_document_types - Edition::NON_RENDERABLE_FORMATS
                         renderable_types.sample
                       else
                         Edition::NON_RENDERABLE_FORMATS.sample
                       end
  end

  def locale
    return @locale unless @locale == "default"

    Edition::DEFAULT_LOCALE
  end

  def unpublishing_type
    @unpublishing_type ||= begin
      return "withdrawal" if withdrawal

      Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
    end
  end

  def draft?
    state == "draft"
  end

  def unpublished?
    state == "unpublished"
  end

  def document
    @document ||= Document.find_by(content_id:, locale:) ||
      FactoryBot.create(:document, content_id:, locale:)
  end
end

class TestCase
  def initialize(
    with_drafts:,
    default_root_locale:,
    linked_editions:
  )
    @with_drafts = with_drafts
    @default_root_locale = default_root_locale
    @linked_editions_input = linked_editions
  end

  attr_reader :with_drafts

  def source_edition
    @source_edition ||= FactoryBot.create(
      :live_edition,
      document: FactoryBot.create(
        :document,
        locale: root_locale,
      ),
      edition_links: edition_linked_editions.map do
        { link_type:, target_content_id: it.content_id }
      end,
      link_set_links: link_set_linked_editions.map do
        { link_type:, target_content_id: it.content_id }
      end,
    )
  end

  def link_type
    @link_type ||= if linked_editions_input.any? { it[:permitted_unpublished_link_type] }
                     Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
                   else
                     "ordered_related_items"
                   end
  end

  def description
    "is consistent with linked editions: #{linked_editions_input.inspect}"
  end

  def with_drafts_description
    "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
  end

  def source_edition_locale_description
    "when the source edition's locale is #{default_root_locale ? 'default' : 'non-default'}"
  end

private

  attr_reader :default_root_locale, :linked_editions_input

  def target_content_id
    @target_content_id ||= SecureRandom.uuid
  end

  def link_set_linked_editions
    @link_set_linked_editions ||= linked_editions_input
      .filter { it[:link_kind] == "link_set" }
      .map do
        TestLinkedEditionFactory.new(
          **it.except(:permitted_unpublished_link_type),
          content_id: target_content_id,
        ).call
      end
  end

  def edition_linked_editions
    @edition_linked_editions ||= linked_editions_input
      .filter { it[:link_kind] == "edition" }
      .map do
        TestLinkedEditionFactory.new(
          **it.except(:permitted_unpublished_link_type),
          content_id: target_content_id,
        ).call
      end
  end

  def root_locale
    return Edition::DEFAULT_LOCALE if default_root_locale

    "fr"
  end
end

class TestCaseFactory
  class << self
    def all
      @all ||= begin
        query_values = [
          { with_drafts: true, default_root_locale: true },
          { with_drafts: true, default_root_locale: false },
          { with_drafts: false, default_root_locale: true },
          { with_drafts: false, default_root_locale: false },
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
        locale_values = %w[default fr hu]

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

        test_cases = query_values.product(edition_values.combination(2).to_a)
          .map { { **_1, linked_editions: _2 } }

        test_cases.reject! do |test_case|
          [
            # We only need the following cases.
            # root_locale: "default", locale: "default"
            # root_locale: "default", locale: "fr"
            # root_locale: "fr", locale: "default"
            # root_locale: "fr", locale: "fr"
            # root_locale: "fr", locale: "hu"
            test_case[:default_root_locale] && test_case[:linked_editions].any? { it[:locale] == "hu" },

            # the link type must be the same for two targets to compete, so we need to
            # filter out cases where we have both true and false for the permitted
            # unpublished link type (from which we derive the link type)
            test_case[:linked_editions].map { it[:permitted_unpublished_link_type] }.compact.uniq.size > 1,

            # A single document can't be in the live content store twice with different
            # states. The two test cases are the same document if they have the same
            # locale, because we already assume that they have the same Content ID.
            if fields_equal(*test_case[:linked_editions], :locale)
              test_case[:linked_editions].map { it[:state] }.sort == %w[published unpublished]
            else
              false
            end,

            # if the state and locale are the same (where the content id is also the
            # same), they're the same edition so they can't have a different document
            # type
            fields_equal(*test_case[:linked_editions], :state, :locale) &&
              !fields_equal(*test_case[:linked_editions], :renderable_document_type),
          ].any?
        end

        test_cases.map { TestCase.new(**it) }
      end
    end

  private

    def fields_equal(a, b, *fields) # rubocop:disable Naming/MethodParameterName
      fields.all? { a[it] == b[it] }
    end
  end
end

# 4664
# puts TestCaseFactory.all.count

RSpec.describe "link expansion precedence" do
  def for_content_store(source_edition, link_type:, with_drafts:)
    Presenters::Queries::ExpandedLinkSet
      .by_edition(source_edition, with_drafts:)
      .links
      .fetch(link_type.to_sym, [])
  end

  def for_graphql(source_edition, link_type:, with_drafts:)
    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        Sources::LinkedToEditionsSource,
        with_drafts:,
        locale: source_edition.locale,
      ).request([source_edition, link_type])

      request.load
    end
  end

  TestCaseFactory.all.each do |test_case| # rubocop:disable Rails/FindEach
    context test_case.with_drafts_description do
      context test_case.source_edition_locale_description do
        it test_case.description do
          content_store_result = for_content_store(
            test_case.source_edition,
            link_type: test_case.link_type,
            with_drafts: test_case.with_drafts,
          )
          skip "content store returns two links sometimes, e.g. when there's a non-renderable draft and a renderable live edition" if content_store_result.size > 1

          graphql_result = for_graphql(
            test_case.source_edition,
            link_type: test_case.link_type,
            with_drafts: test_case.with_drafts,
          )

          aggregate_failures do
            expect(content_store_result.map { it[:title] })
              .to eq(graphql_result.map(&:title))
            expect(content_store_result.size).to be <= 1
            expect(graphql_result.size).to be <= 1
          end
        end
      end
    end
  end
end
