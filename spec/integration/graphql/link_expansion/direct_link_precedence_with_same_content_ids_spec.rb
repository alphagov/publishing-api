RSpec.describe "precedence of direct-linked editions with the same content ID" do
  GraphqlLinkExpansionPrecedenceHelpers::DirectLinks::TestCaseFactory
    .all(target_content_ids_differ: false)
    .each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.source_edition_locale_description do
          it test_case.description do
            aggregate_failures do
              expect(test_case.graphql_titles).to eq(test_case.content_store_titles)
              expect(test_case.content_store_titles.size).to be <= 1
              expect(test_case.graphql_titles.size).to be <= 1
            end
          end
        end
      end
    end
end
