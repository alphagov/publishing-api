require "parity/link_expansion_parity_helper"

# 5704
# puts LinkExpansionPrecedenceTestHelpers.TestCaseFactory.all(target_content_ids_differ: true).count

RSpec.describe "link expansion precedence when targeting different content IDs" do
  LinkExpansionPrecedenceTestHelpers::TestCaseFactory.all(target_content_ids_differ: true).each do |test_case| # rubocop:disable Rails/FindEach
    context test_case.with_drafts_description do
      context test_case.source_edition_locale_description do
        it test_case.description do
          aggregate_failures do
            graphql_titles = test_case.graphql_result.map(&:title)
            content_store_titles = test_case
              .content_store_result
              .map { it[:title] }

            if (graphql_titles != content_store_titles) &&
                test_case.has_link_of_kind?(:edition) &&
                !test_case.has_valid_link_of_kind?(:edition) &&
                test_case.has_valid_link_of_kind?(:link_set)
              # this is a known diff between Content Store and GraphQL so we're
              # just checking that the GraphQL result is 'correct' and not that
              # it matches Content Store

              expect(graphql_titles.size).to be(1)
              expect(graphql_titles.first).to match(/link_set/)
            else
              expect(graphql_titles).to eq(content_store_titles)
            end
          end
        end
      end
    end
  end
end
