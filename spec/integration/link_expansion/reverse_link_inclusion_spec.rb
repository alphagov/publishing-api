RSpec.describe "reverse link expansion inclusion" do
  def links_for(target_edition, link_type:, with_drafts:)
    reverse_link_type = ExpansionRules::REVERSE_LINKS[link_type.to_sym] || link_type
    Presenters::Queries::ExpandedLinkSet
      .by_edition(target_edition, with_drafts:)
      .links
      .fetch(reverse_link_type, [])
  end

  test_cases = LinkExpansionInclusionHelpers::ReverseLinks::TestCaseFactory.all

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

            result = links_for(
              linked_edition,
              link_type: test_case.link_type,
              with_drafts: test_case.with_drafts?,
            )

            if test_case.included
              expect(result.size).to eq(1)
            else
              expect(result).to be_empty
            end
          end
        end
      end
    end
  end
end
