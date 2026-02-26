RSpec.describe "precedence of direct-linked editions with different content IDs" do
  GraphqlLinkExpansionPrecedenceHelpers::DirectLinks::TestCaseFactory
    .all(target_content_ids_differ: true)
    .each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.source_edition_locale_description do
          it test_case.description do
            aggregate_failures do
              if test_case.graphql_titles != test_case.content_store_titles &&
                  test_case.invalid_edition_and_valid_link_set_linked_editions?
                # this is a known diff between Content Store and GraphQL so
                # we're just checking that the GraphQL result is 'correct' and
                # not that it matches Content Store

                expect(test_case.content_store_titles.size).to be(0)
                expect(test_case.graphql_titles.size).to be(1)
                expect(test_case.graphql_titles.first).to match(/link_set/)
              else
                expect(test_case.graphql_titles).to eq(test_case.content_store_titles)
              end
            end
          end
        end
      end
    end
end
