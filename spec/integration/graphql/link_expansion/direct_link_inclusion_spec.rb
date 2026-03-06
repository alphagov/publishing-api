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

  test_cases = GraphqlLinkExpansionInclusionHelpers::DirectLinks::TestCaseFactory.all

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
