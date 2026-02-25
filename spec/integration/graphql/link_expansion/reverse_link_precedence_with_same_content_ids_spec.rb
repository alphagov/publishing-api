RSpec.describe "precedence of reverse-linked editions with the same content ID" do
  GraphqlLinkExpansionPrecedenceHelpers::ReverseLinks::TestCaseFactory
    .all(source_content_ids_differ: false)
    .each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.linked_edition_locale_description do
        it test_case.description do
          aggregate_failures do
            if test_case.graphql_titles != test_case.content_store_titles &&
                test_case.invalid_root_locale_and_valid_default_locale_edition_linking_editions?
              # this is a known diff between Content Store and GraphQL so
              # we're just checking that the results match our expectations

              expect(test_case.content_store_titles.size).to eq(1)
              expect(test_case.content_store_result.first[:locale])
                .to eq(Edition::DEFAULT_LOCALE)
              expect(test_case.graphql_titles.size).to eq(0)
            elsif test_case.graphql_titles != test_case.content_store_titles &&
                test_case.valid_published_default_locale_and_unpublished_differing_root_locale_edition_linking_editions?
              # this is a known diff between Content Store and GraphQL so
              # we're just checking that the results match our expectations

              expect(test_case.content_store_titles.size).to eq(1)
              expect(test_case.content_store_result.first[:locale])
                .to eq(Edition::DEFAULT_LOCALE)
              expect(test_case.graphql_titles.size).to eq(1)
              test_case.graphql_result.first.then do |edition|
                expect(edition.state).to eq("unpublished")
                expect(edition.locale).not_to eq(Edition::DEFAULT_LOCALE)
              end
            else
              expect(test_case.graphql_titles).to eq(test_case.content_store_titles)
              expect(test_case.content_store_titles.size).to be <= 1
              expect(test_case.graphql_titles.size).to be <= 1
            end
          end
        end
      end
  end
end
