require "rails_helper"

RSpec.describe "POST /lookup-by-base-path", type: :request do
  context "validating" do
    it "requires a base_paths param" do
      expected_error_response = { "error" => { "code" => 422, "message" => "param is missing or the value is empty: base_paths" } }

      post "/lookup-by-base-path"

      expect(parsed_response).to eql(expected_error_response)
    end
  end

  context "with content in different states" do
    let(:published_with_new_draft) {FactoryGirl.create(:document, content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")}
    let(:published_with_no_drafts) {FactoryGirl.create(:document, content_id: "bbabcd3c-7c45-4403-8490-db51e4bfc4f6")}
    let(:two_initial_drafts) {FactoryGirl.create(:document, content_id: "dd1bf833-f91c-4e45-9f97-87b165808176")}
    let(:redirected) {FactoryGirl.create(:document, content_id: "ee491126-77ed-4e81-91fa-8dc7f74e9657")}
    let(:gone) {FactoryGirl.create(:document, content_id: "ffabcd3c-7c45-4403-8490-db51e4bfc4f6")}
    let(:withdrawn) {FactoryGirl.create(:document, content_id: "00abcd3c-7c45-4403-8490-db51e4bfc4f6")}
    let(:initial_draft) {FactoryGirl.create(:document, content_id: "01abcd3c-7c45-4403-8490-db51e4bfc4f6")}
    let(:unpublished_without_draft) {FactoryGirl.create(:document, content_id: "02abcd3c-7c45-4403-8490-db51e4bfc4f6")}
    let(:reused_base_path) {FactoryGirl.create(:document, content_id: "03abcd3c-7c45-4403-8490-db51e4bfc4f6")}

    before do
      FactoryGirl.create(:live_edition, state: "published", base_path: "/published-and-draft-page", document: published_with_new_draft, user_facing_version: 1)
      FactoryGirl.create(:edition, state: "draft", base_path: "/published-and-draft-page", document: published_with_new_draft, user_facing_version: 2)
      FactoryGirl.create(:live_edition, state: "published", base_path: "/only-published-page", document: published_with_no_drafts)
      FactoryGirl.create(:edition, state: "draft", base_path: "/draft-and-superseded-page", document: two_initial_drafts, user_facing_version: 2)
      FactoryGirl.create(:superseded_edition, state: "superseded", base_path: "/draft-and-superseded-page", document: two_initial_drafts, user_facing_version: 1)
      FactoryGirl.create(:edition, state: "draft", base_path: "/only-draft-page", document: initial_draft, user_facing_version: 1)

      unpublished1 = FactoryGirl.create(:live_edition, state: "published", base_path: "/redirected-from-page", document: redirected, user_facing_version: 1)
      unpublished1.unpublish(type: "redirect", alternative_path: "/redirected-to-page")

      unpublished2 = FactoryGirl.create(:live_edition, state: "published", base_path: "/gone-page", document: gone, user_facing_version: 1)
      unpublished2.unpublish(type: "gone")

      unpublished3 = FactoryGirl.create(:live_edition, state: "published", base_path: "/withdrawn-page", document: withdrawn, user_facing_version: 1)
      unpublished3.unpublish(type: "withdrawal", explanation: "Consolidated into another page")
    end

    it "includes published pages" do
      post "/lookup-by-base-path", params: { base_paths: %w(/only-published-page) }

      expect(parsed_response).to eql(
        "/only-published-page" => published_with_no_drafts.content_id,
      )
    end

    it "includes draft pages" do
      post "/lookup-by-base-path", params: { base_paths: %w(/only-draft-page) }

      expect(parsed_response).to eql(
        "/only-draft-page" => initial_draft.content_id,
      )
    end

    it "includes withdrawn pages" do
      post "/lookup-by-base-path", params: { base_paths: %w(/withdrawn-page) }

      expect(parsed_response).to eql(
        "/withdrawn-page" => withdrawn.content_id
      )
    end

    it "picks withdrawn editions over drafts if the base path has been reused" do
      replacement = FactoryGirl.create(:document, content_id: "ab491126-77ed-4e81-91fa-8dc7f74e9657")
      FactoryGirl.create(:edition, state: "draft", base_path: "/withdrawn-page", document: replacement, user_facing_version: 1)

      post "/lookup-by-base-path", params: { base_paths: %w(/withdrawn-page) }

      expect(parsed_response).to eql(
        "/withdrawn-page" => withdrawn.content_id
      )
    end

    it "picks published editions over drafts if the base path has been reused" do
      replacement = FactoryGirl.create(:document, content_id: "ab491126-77ed-4e81-91fa-8dc7f74e9657")
      FactoryGirl.create(:edition, state: "draft", base_path: "/only-published-page", document: replacement, user_facing_version: 1)

      post "/lookup-by-base-path", params: { base_paths: %w(/only-published-page) }

      expect(parsed_response).to eql(
        "/only-published-page" => published_with_no_drafts.content_id
      )
    end

    it "excludes unpublished content that is not withdrawn" do
      post "/lookup-by-base-path", params: { base_paths: %w(redirected-from-page gone-page) }

      expect(parsed_response).to eql({})
    end

    it "looks up multiple base paths and returns the ones that match" do
      test_base_paths = [
        "/published-and-draft-page",
        "/only-published-page",
        "/draft-and-superseded-page",
        "/does-not-exist",
        "/redirected-from-page",
        "/gone-page",
        "/withdrawn-page",
        "/only-draft-page"
      ]

      post "/lookup-by-base-path", params: { base_paths: test_base_paths }

      expect(parsed_response).to eql(
        "/draft-and-superseded-page" => two_initial_drafts.content_id,
        "/published-and-draft-page" => published_with_new_draft.content_id,
        "/only-published-page" => published_with_no_drafts.content_id,
        "/withdrawn-page" => withdrawn.content_id,
        "/only-draft-page" => initial_draft.content_id,
      )
    end
  end

  it "excludes content items with document_type redirect" do
    FactoryGirl.create(:redirect_edition, state: "published", base_path: "/redirect-page", user_facing_version: 1)

    post "/lookup-by-base-path", params: { base_paths: %w(/redirect-page) }

    expect(parsed_response).to eql({})
  end

  it "excludes content items with document_type gone" do
    FactoryGirl.create(:gone_edition, state: "published", base_path: "/gone-page", user_facing_version: 1)

    post "/lookup-by-base-path", params: { base_paths: %w(/gone-page) }

    expect(parsed_response).to eql({})
  end

end
