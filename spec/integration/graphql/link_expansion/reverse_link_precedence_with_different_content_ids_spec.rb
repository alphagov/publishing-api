RSpec.describe "precedence of reverse-linked editions with different content IDs" do
  GraphqlLinkExpansionPrecedenceHelpers::ReverseLinks::TestCaseFactory
    .all(source_content_ids_differ: true)
    .each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.linked_edition_locale_description do
          it test_case.description do
            aggregate_failures do
              if test_case.graphql_titles != test_case.content_store_titles &&
                  test_case.invalid_edition_and_valid_link_set_linking_source_editions?
                # this is a known diff between Content Store and GraphQL so
                # we're just checking that the GraphQL result is 'correct' and
                # not that it matches Content Store

                expect(test_case.content_store_titles.size).to be(0)
                expect(test_case.graphql_titles.size).to be(1)
                expect(test_case.graphql_titles.first).to match(/link_set/)
              elsif test_case.graphql_titles != test_case.content_store_titles &&
                  test_case.valid_edition_and_link_set_linking_editions?
                # this is a known diff between Content Store and GraphQL so
                # we're just checking that the results match our expectations

                expect(test_case.content_store_titles.size).to be(1)
                expect(test_case.content_store_titles.first).to match(/edition/)
                expect(test_case.graphql_titles.size).to be(2)
              else
                expect(test_case.graphql_titles).to eq(test_case.content_store_titles)
              end
            end
          end
        end
      end
  end
end
