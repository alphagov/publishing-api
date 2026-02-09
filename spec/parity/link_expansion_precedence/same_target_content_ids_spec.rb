require "parity/link_expansion_parity_helper"

# 4664
# puts LinkExpansionPrecedenceTestHelpers.TestCaseFactory.all(target_content_ids_differ: false).count

RSpec.describe "link expansion precedence when targeting the same content ID" do
  LinkExpansionPrecedenceTestHelpers::TestCaseFactory.all(target_content_ids_differ: false).each do |test_case| # rubocop:disable Rails/FindEach
    context test_case.with_drafts_description do
      context test_case.source_edition_locale_description do
        it test_case.description do
          aggregate_failures do
            graphql_titles = test_case.graphql_result.map(&:title)
            content_store_titles = test_case
              .content_store_result
              .map { it[:title] }

            expect(graphql_titles).to eq(content_store_titles)
            expect(test_case.content_store_result.size).to be <= 1
            expect(test_case.graphql_result.size).to be <= 1
          end
        end
      end
    end
  end
end
