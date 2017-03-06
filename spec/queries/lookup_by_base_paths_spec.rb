require "rails_helper"

RSpec.describe Queries::LookupByBasePaths do
  describe "#call" do
    before { Rails.cache.clear }

    context "with draft, superseded, published and unpublished editions" do
      let(:published_with_new_draft) { FactoryGirl.create(:document, content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657") }
      let(:published_with_no_drafts) { FactoryGirl.create(:document, content_id: "bbabcd3c-7c45-4403-8490-db51e4bfc4f6") }
      let(:two_initial_drafts) { FactoryGirl.create(:document, content_id: "dd1bf833-f91c-4e45-9f97-87b165808176") }
      let(:redirected) { FactoryGirl.create(:document, content_id: "ee491126-77ed-4e81-91fa-8dc7f74e9657") }
      let(:gone) { FactoryGirl.create(:document, content_id: "ffabcd3c-7c45-4403-8490-db51e4bfc4f6") }
      let(:withdrawn) { FactoryGirl.create(:document, content_id: "00abcd3c-7c45-4403-8490-db51e4bfc4f6") }
      let(:initial_draft) { FactoryGirl.create(:document, content_id: "01abcd3c-7c45-4403-8490-db51e4bfc4f6") }
      let(:unpublished_without_draft) { FactoryGirl.create(:document, content_id: "02abcd3c-7c45-4403-8490-db51e4bfc4f6") }
      let(:reused_base_path) { FactoryGirl.create(:document, content_id: "03abcd3c-7c45-4403-8490-db51e4bfc4f6") }

      before do
        FactoryGirl.create(:live_edition, state: "published", base_path: "/published-and-draft-page", document: published_with_new_draft, user_facing_version: 1, document_type: "publication")
        FactoryGirl.create(:edition, state: "draft", base_path: "/published-and-draft-page", document: published_with_new_draft, user_facing_version: 2, document_type: "publication")
        FactoryGirl.create(:live_edition, state: "published", base_path: "/only-published-page", document: published_with_no_drafts, document_type: "publication")
        FactoryGirl.create(:edition, state: "draft", base_path: "/draft-and-superseded-page", document: two_initial_drafts, user_facing_version: 2, document_type: "publication")
        FactoryGirl.create(:superseded_edition, state: "superseded", base_path: "/draft-and-superseded-page", document: two_initial_drafts, user_facing_version: 1, document_type: "publication")
        FactoryGirl.create(:edition, state: "draft", base_path: "/only-draft-page", document: initial_draft, user_facing_version: 1, document_type: "publication")
        FactoryGirl.create(:unpublished_edition, base_path: "/redirected-from-page", document: redirected, user_facing_version: 1, unpublishing_type: "redirect", alternative_path: "/redirected-to-page", document_type: "publication")
        FactoryGirl.create(:unpublished_edition, base_path: "/gone-page", document: gone, user_facing_version: 1, unpublishing_type: "gone", alternative_path: nil, document_type: "publication")
        FactoryGirl.create(:unpublished_edition, base_path: "/withdrawn-page", document: withdrawn, user_facing_version: 1, unpublishing_type: "withdrawal", explanation: "Consolidated into another page", alternative_path: nil, document_type: "publication")
      end

      it "returns published pages" do
        response = Queries::LookupByBasePaths.call(%w(/only-published-page))

        expect(response).to eql(
          "/only-published-page" => {
            "live" => {
              "content_id" => published_with_no_drafts.content_id,
              "locale" => "en",
              "document_type" => "publication",
            }
          }
        )
      end

      it "returns draft pages" do
        response = Queries::LookupByBasePaths.call(%w(/only-draft-page))

        expect(response).to eql(
          "/only-draft-page" => {
            "draft" => {
              "content_id" => initial_draft.content_id,
              "locale" => "en",
              "document_type" => "publication",
            }
          }
        )
      end

      it "includes withdrawn pages" do
        response = Queries::LookupByBasePaths.call(%w(/withdrawn-page))

        expect(response).to eql(
          "/withdrawn-page" => {
            "live" => {
              "content_id" => withdrawn.content_id,
              "locale" => "en",
              "document_type" => "publication",
              "unpublishing" => {
                "type" => "withdrawal",
              }
            }
          }
        )
      end

      it "returns different content ids if the base path has been reused" do
        replacement_content_id = "ab491126-77ed-4e81-91fa-8dc7f74e9657"
        replacement = FactoryGirl.create(:document, content_id: replacement_content_id)
        FactoryGirl.create(:edition, state: "draft", base_path: "/withdrawn-page", document: replacement, user_facing_version: 1, document_type: "publication")

        response = Queries::LookupByBasePaths.call(%w(/withdrawn-page))

        expect(response).to eql(
          "/withdrawn-page" => {
            "draft" => {
              "content_id" => replacement_content_id,
              "locale" => "en",
              "document_type" => "publication",
            },
            "live" => {
              "content_id" => withdrawn.content_id,
              "locale" => "en",
              "document_type" => "publication",
              "unpublishing" => {
                "type" => "withdrawal",
              }
            },
          }
        )
      end

      it "returns unpublished content" do
        response = Queries::LookupByBasePaths.call(%w(/redirected-from-page /gone-page /withdrawn-page))

        expect(response).to eql(
          "/gone-page" => {
            "live" => {
              "content_id" => gone.content_id,
              "locale" => "en",
              "document_type" => "publication",
              "unpublishing" => {
                "type" => "gone",
              }
            },
          },
          "/redirected-from-page" => {
            "live" => {
              "content_id" => redirected.content_id,
              "locale" => "en",
              "document_type" => "publication",
              "unpublishing" => {
                "type" => "redirect",
                "alternative_path" => "/redirected-to-page"
              }
            },
          },
          "/withdrawn-page" => {
            "live" => {
              "content_id" => withdrawn.content_id,
              "locale" => "en",
              "document_type" => "publication",
              "unpublishing" => {
                "type" => "withdrawal",
              }
            }
          }
        )
      end

      it "ignores paths that do not match" do
        test_base_paths = [
          "/only-published-page",
          "/does-not-exist",
          "/only-draft-page"
        ]

        response = Queries::LookupByBasePaths.call(test_base_paths)

        expect(response).to eql(
          "/only-published-page" => {
            "live" => {
              "content_id" => published_with_no_drafts.content_id,
              "locale" => "en",
              "document_type" => "publication"
            },
          },
          "/only-draft-page" => {
            "draft" => {
              "content_id" => initial_draft.content_id,
              "locale" => "en",
              "document_type" => "publication"
            }
          }
        )
      end
    end

    it "returns content items with document_type redirect" do
      edition = FactoryGirl.create(:redirect_edition, state: "published", base_path: "/redirect-page")

      response = Queries::LookupByBasePaths.call(edition.base_path)

      expect(response).to eql(
        "/redirect-page" => {
          "live" => {
            "content_id" => edition.content_id,
            "locale" => "en",
            "document_type" => "redirect"
          }
        }
      )
    end

    it "returns content items with document_type gone" do
      edition = FactoryGirl.create(:gone_edition, state: "published", base_path: "/gone-page")

      response = Queries::LookupByBasePaths.call(edition.base_path)

      expect(response).to eql(
        "/gone-page" => {
          "live" => {
            "content_id" => edition.content_id,
            "locale" => "en",
            "document_type" => "gone"
          }
        }
      )
    end

    it "excludes access-limited editions" do
      FactoryGirl.create(:access_limited_edition, base_path: "/access-limited")

      response = Queries::LookupByBasePaths.call(%w(/access-limited))

      expect(response).to eql({})
    end
  end
end
