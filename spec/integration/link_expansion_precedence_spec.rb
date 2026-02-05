TestLinkedEdition = Struct.new(
  :state,
  :renderable_document_type,
  :locale,
  :withdrawal,
  :permitted_unpublished_link_type,
  :link_kind,
  keyword_init: true,
) do
  def document_type
    @document_type ||= if renderable_document_type
                                        renderable_types = GovukSchemas::DocumentTypes.valid_document_types - Edition::NON_RENDERABLE_FORMATS
                                        renderable_types.sample
                                      else
                                        Edition::NON_RENDERABLE_FORMATS.sample
                                      end
  end

  def locale
    return locale unless locale == "default"

    Edition::DEFAULT_LOCALE
  end

  def unpublishing_type
    @unpublishing_type ||= begin
      return "withdrawal" if withdrawal

      Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
    end
  end

  def link_type
    @link_type ||= begin
      return "ordered_related_items" unless permitted_unpublished_link_type

      Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
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
    "description"
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

  def test_linked_editions
    @test_linked_editions ||= linked_editions.map do
      TestLinkedEdition.new(it)
    end
  end

  def with_drafts_description
    "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
  end

  def source_edition_locale_description
    "when the source edition's locale is #{default_root_locale ? 'default' : 'non-default'}"
  end

  def root_locale
    return Edition::DEFAULT_LOCALE if default_root_locale

    "fr"
  end
end

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

  test_cases = YAML
    .load_file("precedence.yaml")
    .map { TestCase.new(it.symbolize_keys) }

  test_cases.each do |test_case|
    context test_case.with_drafts_description do
      context test_case.source_edition_locale_description do
        it test_case.description do
          test_linked_editions = test_case.test_linked_editions.map.with_index do | object, index |
            test_linked_edition = create(
              :edition,
              title: "Edition #{index}",
              state: it.state,
              document_type: it.document_type,
              document: create(
                :document,
                locale: it.locale,
              ),
            )
            if test_linked_edition.state == "unpublished"
              create(
                :unpublishing,
                edition: linked_edition,
                type: test_case.linked_edition_unpublishing_type,
              )
            end
          end


          source_edition = create(
            :live_edition,
            document: create(
              :document,
              locale: test_case.root_locale,
            ),
            link_kind => test_linked_editions.map do
              [
                {
                  link_type: test_case.link_type,
                  target_content_id: it.content_id,
                },
              ]
            end,
          )

          %w[content_store graphql].each do |destination|
            result = send(
              :"for_#{destination}",
              source_edition,
              **{
                link_type: test_case.link_type,
                with_drafts: test_case.with_drafts,
              },
            )

            if test_case.included
              expect(result.size).to(
                eq(1),
                "unexpected exclusion for #{destination}",
              )
            else
              expect(result).to(
                be_empty,
                "unexpected inclusion for #{destination}",
              )
            end
          end
        end
      end
    end
  end
end
