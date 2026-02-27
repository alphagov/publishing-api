RSpec.describe "reverse link expansion inclusion" do
  def for_content_store(target_edition, link_type:, with_drafts:)
    reverse_link_type = ExpansionRules::REVERSE_LINKS.dig(link_type.to_sym) || link_type
    Presenters::Queries::ExpandedLinkSet
      .by_edition(target_edition, with_drafts:)
      .links
      .fetch(reverse_link_type, [])
  end

  def for_graphql(target_edition, link_type:, with_drafts:)
    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        Sources::ReverseLinkedToEditionsSource,
        content_store: with_drafts ? "draft" : "live",
        locale: target_edition.locale,
      ).request([target_edition, link_type])

      request.load
    end
  end

  test_cases = GraphqlLinkExpansionInclusionHelpers::ReverseLinks::TestCaseFactory.all

  test_cases.each do |test_case|
    context "when the link kind is #{test_case.link_kind}" do
      context test_case.with_drafts_description do
        context test_case.target_edition_locale_description do
          it test_case.description do
            linked_edition = create(
              :live_edition,
              document: create(
                :document,
                locale: test_case.root_locale,
              ),
            )

            source_edition = create(
              :edition,
              state: test_case.state,
              content_store: test_case.state == "draft" ? "draft" : "live",
              document_type: test_case.source_edition_document_type,
              document: create(
                :document,
                locale: test_case.locale,
              ),
              test_case.link_kind => [
                {
                  link_type: test_case.link_type,
                  target_content_id: linked_edition.content_id,
                },
              ],
            )

            if test_case.state == "unpublished"
              create(
                :unpublishing,
                edition: source_edition,
                type: test_case.source_edition_unpublishing_type,
              )
            end

            %w[content_store graphql].each do |destination|
              # GraphQL doesn't yet support drafts
              next if destination == "graphql" && test_case.with_drafts

              # GraphQL will only attempt to find a reverse link for a field that is declared
              # as a reverse_links_field in app/graphql/types/edition_type.rb. This test
              # calls the dataloader directly, but the dataloader won't check that the
              # link type is reversible, so we should skip irreversible link types.
              next if destination == "graphql" && !test_case.allowed_reverse_link_type

              result = send(
                :"for_#{destination}",
                linked_edition,
                **{
                  link_type: test_case.link_type,
                  with_drafts: test_case.with_drafts,
                },
              )

              if test_case.included
                # if result.size != 1
                #   byebug
                # end
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
