RSpec.describe "precedence of reverse-linked editions with different content IDs" do
  LinkExpansionPrecedenceHelpers::ReverseLinks::TestCaseFactory
    .all(source_content_ids_differ: true)
    .each do |test_case| # rubocop:disable Rails/FindEach
    context test_case.with_drafts_description do
      context test_case.linked_edition_locale_description do
        it test_case.description do
          expect(test_case.content_store_titles).to match_array(test_case.expected_titles)
        end
      end
    end
  end
end
