module LinkExpansionInclusionTestHelpers
  class TestCase
    def initialize(
      with_drafts:,
      root_locale:,
      state:,
      renderable_document_type:,
      locale:,
      withdrawal:,
      permitted_unpublished_link_type:
    )
      @with_drafts = with_drafts
      @root_locale = root_locale
      @state = state
      @renderable_document_type = renderable_document_type
      @locale = locale
      @withdrawal = withdrawal
      @permitted_unpublished_link_type = permitted_unpublished_link_type
    end

    attr_reader :with_drafts, :root_locale, :state, :renderable_document_type, :locale

    def description
      inclusion_string = included ? "includes" : "excludes"
      state_string = if state == "unpublished"
                       link_type_description = permitted_unpublished_link_type ? "permitted" : "unpermitted"
                       unpublishing_type_description = withdrawal ? "withdrawal" : "non-withdrawal"
                       "an unpublished #{unpublishing_type_description} with a #{link_type_description} link type"
                     else
                       state
                     end
      locale_string = locale == "default" ? "in the default locale" : "in the locale \"#{locale}\""
      document_type_string = "a #{renderable_document_type ? 'renderable' : 'non-renderable'} document type"

      "#{inclusion_string} a target edition that is #{[state_string, document_type_string, locale_string].to_sentence}"
    end

    def with_drafts_description
      "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
    end

    def source_edition_locale_description
      "when the source edition's locale is \"#{root_locale}\""
    end

    def linked_edition_document_type
      @linked_edition_document_type ||= if renderable_document_type
                                          renderable_types = GovukSchemas::DocumentTypes.valid_document_types - Edition::NON_RENDERABLE_FORMATS
                                          renderable_types.sample
                                        else
                                          Edition::NON_RENDERABLE_FORMATS.sample
                                        end
    end

    def link_type
      @link_type ||= begin
        return "ordered_related_items" unless permitted_unpublished_link_type

        Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
      end
    end

    def linked_edition_unpublishing_type
      @linked_edition_unpublishing_type ||= begin
        return "withdrawal" if withdrawal

        Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
      end
    end

    def included
      renderable_document_type &&
        (with_drafts || state != "draft") &&
        (state != "unpublished" ||
         (withdrawal && permitted_unpublished_link_type)
        ) &&
        [Edition::DEFAULT_LOCALE, root_locale].include?(locale)
    end

  private

    attr_reader :withdrawal, :permitted_unpublished_link_type
  end

  class TestCaseFactory
    class << self
      def all
        with_drafts_values = [true, false]
        root_locale_values = [Edition::DEFAULT_LOCALE, "fr"]

        state_values = %w[published unpublished draft]
        withdrawal_values = [true, false, nil]
        permitted_unpublished_link_type_values = [true, false, nil]

        renderable_document_type_values = [false, true]
        locale_values = [Edition::DEFAULT_LOCALE, "fr", "hu"]

        with_drafts_values.product(
          root_locale_values,
          state_values,
          withdrawal_values,
          permitted_unpublished_link_type_values,
          renderable_document_type_values,
          locale_values,
        ).map {
          {
            with_drafts: _1,
            root_locale: _2,
            state: _3,
            withdrawal: _4,
            permitted_unpublished_link_type: _5,
            renderable_document_type: _6,
            locale: _7,
          }
        }
          .reject { |test_case|
            [
              redundant_locale(test_case),
              invalid_state(test_case),
            ].any?
          }
            .map { TestCase.new(**it) }
      end

    private

      def redundant_locale(test_case)
        test_case[:root_locale] == Edition::DEFAULT_LOCALE &&
          test_case[:locale] == "hu"
      end

      def invalid_state(test_case)
        if test_case[:state] == "unpublished"
          test_case[:withdrawal].nil? || test_case[:permitted_unpublished_link_type].nil?
        else
          !test_case[:withdrawal].nil? || !test_case[:permitted_unpublished_link_type].nil?
        end
      end
    end
  end
end

RSpec.describe "link expansion inclusion" do
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
        content_store: with_drafts ? "draft" : "live",
        locale: source_edition.locale,
      ).request([source_edition, link_type])

      request.load
    end
  end

  test_cases = LinkExpansionInclusionTestHelpers::TestCaseFactory.all

  %i[link_set_links edition_links].each do |link_kind|
    context "when the link kind is #{link_kind}" do
      test_cases.each do |test_case|
        context test_case.with_drafts_description do
          context test_case.source_edition_locale_description do
            it test_case.description do
              linked_edition = create(
                :edition,
                state: test_case.state,
                content_store: test_case.state == "draft" ? "draft" : "live",
                document_type: test_case.linked_edition_document_type,
                document: create(
                  :document,
                  locale: test_case.locale,
                ),
              )

              if test_case.state == "unpublished"
                create(
                  :unpublishing,
                  edition: linked_edition,
                  type: test_case.linked_edition_unpublishing_type,
                )
              end

              source_edition = create(
                :live_edition,
                document: create(
                  :document,
                  locale: test_case.root_locale,
                ),
                link_kind => [
                  {
                    link_type: test_case.link_type,
                    target_content_id: linked_edition.content_id,
                  },
                ],
              )

              %w[content_store graphql].each do |destination|
                # GraphQL doesn't yet support drafts
                next if destination == "graphql" && test_case.with_drafts

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
  end
end
