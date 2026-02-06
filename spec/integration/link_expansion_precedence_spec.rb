class TestLinkedEdition
  def initialize(
    state:,
    renderable_document_type:,
    locale:,
    withdrawal:,
    permitted_unpublished_link_type:,
    link_kind:
  )
    @state = state
    @renderable_document_type = renderable_document_type
    @locale = locale
    @withdrawal = withdrawal
    @permitted_unpublished_link_type = permitted_unpublished_link_type
    @link_kind = link_kind
  end

  attr_reader :state, :renderable_document_type, :withdrawal, :permitted_unpublished_link_type, :link_kind

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
end

TestCase = Struct.new(
  :with_drafts,
  :default_root_locale,
  :linked_editions,
  keyword_init: true,
) do
  def description
    inspect
    # inclusion_string = included ? "includes" : "excludes"
    # state_string = if state == "unpublished"
    #                  link_type_description = permitted_unpublished_link_type ? "permitted" : "unpermitted"
    #                  unpublishing_type_description = withdrawal ? "withdrawal" : "non-withdrawal"
    #                  "an unpublished #{unpublishing_type_description} with a #{link_type_description} link type"
    #                else
    #                  state
    #                end
    # locale_string = locale == "default" ? "in the default locale" : "in the locale #{locale}"
    # document_type_string = "a #{renderable_document_type ? 'renderable' : 'non-renderable'} document type"
    #
    # "#{inclusion_string} a target edition that is #{[state_string, document_type_string, locale_string].to_sentence}"
  end

  def with_drafts_description
    "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
  end

  def source_edition_locale_description
    "when the source edition's locale is #{default_root_locale ? 'default' : 'non-default'}"
  end

  def test_linked_editions
    @test_linked_editions ||= linked_editions.map do
      TestLinkedEdition.new(**it)
    end
  end

  def link_set_linked_editions
    test_linked_editions.filter { it.link_kind == "link_set" }
  end

  def edition_linked_editions
    test_linked_editions.filter { it.link_kind == "edition" }
  end

  def root_locale
    return Edition::DEFAULT_LOCALE if default_root_locale

    "fr"
  end

  def link_type
    @link_type ||= if test_linked_editions.any?(&:permitted_unpublished_link_type)
                     Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
                   else
                     "ordered_related_items"
                   end
  end
end

# TODO: use precedence cases helper
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

def fields_equal(a, b, *fields) # rubocop:disable Naming/MethodParameterName
  fields.all? { a[it] == b[it] }
end

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

# 4664
puts test_cases.count

test_cases = test_cases.map { TestCase.new(it) }

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

  def find_or_create_document(**fields)
    Document.find_by(**fields) || create(:document, **fields)
  end

  test_cases.each do |test_case|
    context test_case.with_drafts_description do
      context test_case.source_edition_locale_description do
        it test_case.description do
          target_content_id = SecureRandom.uuid
          link_set_linked_editions, edition_linked_editions =
            %w[link_set edition].map do |link_kind|
              test_case.send(:"#{link_kind}_linked_editions")
                .map.with_index do |test_edition, index|
                  create(
                    test_edition.state == "draft" ? :edition : :live_edition,
                    title: "#{link_kind}-linked edition #{index}",
                    state: test_edition.state,
                    document_type: test_edition.document_type,
                    document: find_or_create_document(
                      locale: test_edition.locale,
                      content_id: target_content_id,
                    ),
                  ).tap do
                    if it.state == "unpublished"
                      create(
                        :unpublishing, edition: it, type: test_edition.unpublishing_type
                      )
                    end
                  end
                end
            end

          source_edition = create(
            :live_edition,
            document: create(
              :document,
              locale: test_case.root_locale,
            ),
            edition_links: edition_linked_editions.map do
              [
                {
                  link_type: test_case.link_type,
                  target_content_id: it.content_id,
                },
              ]
            end,
            link_set_links: link_set_linked_editions.map do
              [
                {
                  link_type: test_case.link_type,
                  target_content_id: it.content_id,
                },
              ]
            end,
          )

          content_store_result = for_content_store(
            source_edition,
            link_type: test_case.link_type,
            with_drafts: test_case.with_drafts,
          )

          graphql_result = for_graphql(
            source_edition,
            link_type: test_case.link_type,
            with_drafts: test_case.with_drafts,
          )

          expect(content_store_result.map(&:title))
            .to eq(graphql_result.map(&:title))
          expect(content_store_result.size).to be <= 1
        end
      end
    end
  end
end
