RSpec.describe "precedence of direct-linked editions with different content IDs" do
  LinkExpansionPrecedenceHelpers::DirectLinks::TestCaseFactory
    .all(target_content_ids_differ: true)
    .each do |test_case| # rubocop:disable Rails/FindEach
      context test_case.with_drafts_description do
        context test_case.source_edition_locale_description do
          it test_case.description do
            expect(test_case.content_store_titles).to match_array(test_case.expected_titles)
          end
        end
      end
    end
end
