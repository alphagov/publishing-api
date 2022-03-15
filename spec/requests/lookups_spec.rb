require "rails_helper"

RSpec.describe "POST /lookup-by-base-path", type: :request do
  context "validating" do
    it "requires a base_paths param" do
      expected_error_response = { "error" => { "code" => 422, "message" => "param is missing or the value is empty: base_paths" } }

      post "/lookup-by-base-path"

      expect(parsed_response).to eql(expected_error_response)
    end
  end

  context "returning content_ids" do
    it "returns content_ids for user-visible states (published, withdrawn)" do
      create_test_content

      post "/lookup-by-base-path", params: { base_paths: test_base_paths }

      expect(parsed_response).to eql(
        "/published-and-draft-page" => "aa491126-77ed-4e81-91fa-8dc7f74e9657",
        "/only-published-page" => "bbabcd3c-7c45-4403-8490-db51e4bfc4f6",
        "/withdrawn-page" => "00abcd3c-7c45-4403-8490-db51e4bfc4f6",
      )
    end

    it "returns content_ids including drafts with 'with_draft' option" do
      create_test_content

      post "/lookup-by-base-path", params: { base_paths: test_base_paths, with_drafts: true }

      expect(parsed_response).to eql(
        "/published-and-draft-page" => "aa491126-77ed-4e81-91fa-8dc7f74e9657",
        "/only-draft-page" => "a4038b29-b332-4f13-98b1-1c9709e216bc",
        "/only-published-page" => "bbabcd3c-7c45-4403-8490-db51e4bfc4f6",
        "/superseded-and-draft-page" => "dd1bf833-f91c-4e45-9f97-87b165808176",
        "/withdrawn-page" => "00abcd3c-7c45-4403-8490-db51e4bfc4f6",
      )
    end

    it "returns most relevant content by publishing state for the given parameters" do
      doc1 = create(:document, content_id: "cbb460a7-60de-4a74-b5be-0b27c6d6af9b")
      doc2 = create(:document, content_id: "18020103-122d-459d-90b1-0f3284c1b5cb")

      create(
        :edition,
        state: "draft",
        content_store: "draft",
        base_path: "/unique-base-path",
        document: doc1,
        user_facing_version: 1,
      )
      create(
        :edition,
        state: "published",
        content_store: "live",
        base_path: "/unique-base-path",
        document: doc2,
        user_facing_version: 1,
      )

      post "/lookup-by-base-path", params: { base_paths: "/unique-base-path", with_drafts: true }

      expect(parsed_response).to eql(
        "/unique-base-path" => "cbb460a7-60de-4a74-b5be-0b27c6d6af9b",
      )

      post "/lookup-by-base-path", params: { base_paths: "/unique-base-path" }

      expect(parsed_response).to eql(
        "/unique-base-path" => "18020103-122d-459d-90b1-0f3284c1b5cb",
      )
    end

    it "excludes redirect content items" do
      create(:redirect_edition, state: "published", base_path: "/redirect-page", user_facing_version: 1)

      post "/lookup-by-base-path", params: { base_paths: %w[/redirect-page] }

      expect(parsed_response).to eql({})
    end

    it "excludes gone content items" do
      create(:gone_edition, state: "published", base_path: "/gone-page", user_facing_version: 1)

      post "/lookup-by-base-path", params: { base_paths: %w[/gone-page] }

      expect(parsed_response).to eql({})
    end

    context "when document type filtering is set to include all content" do
      it "returns content ids for redirected content" do
        redirected_content_item = create(
          :redirect_edition,
          state: "published",
          content_store: "live",
          base_path: "/redirect-page",
          user_facing_version: 1,
        )

        post "/lookup-by-base-path", params: { base_paths: %w[/redirect-page], exclude_document_types: %w[none] }

        expect(parsed_response).to eql(
          "/redirect-page" => redirected_content_item.document.content_id,
        )
      end

      it "returns content ids for gone content" do
        gone_content_item = create(
          :gone_edition,
          state: "published",
          content_store: "live",
          base_path: "/gone-page",
          user_facing_version: 1,
        )

        post "/lookup-by-base-path", params: { base_paths: %w[/gone-page], exclude_document_types: %w[none] }

        expect(parsed_response).to eql(
          "/gone-page" => gone_content_item.document.content_id,
        )
      end
    end

    context "when unpublishing type filtering is set to include all content" do
      it "returns content ids for gone content" do
        gone_content_item = create(:unpublished_edition, state: "unpublished", base_path: "/unpublished-gone-page", user_facing_version: 1)

        post "/lookup-by-base-path", params: { base_paths: %w[/unpublished-gone-page], exclude_unpublishing_types: %w[none] }

        expect(parsed_response).to eql(
          "/unpublished-gone-page" => gone_content_item.document.content_id,
        )
      end
    end
  end

  def create_test_content
    doc1 = create(:document, content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")
    doc2 = create(:document, content_id: "bbabcd3c-7c45-4403-8490-db51e4bfc4f6")
    doc3 = create(:document, content_id: "dd1bf833-f91c-4e45-9f97-87b165808176")
    doc4 = create(:document, content_id: "ee491126-77ed-4e81-91fa-8dc7f74e9657")
    doc5 = create(:document, content_id: "ffabcd3c-7c45-4403-8490-db51e4bfc4f6")
    doc6 = create(:document, content_id: "00abcd3c-7c45-4403-8490-db51e4bfc4f6")
    doc7 = create(:document, content_id: "a4038b29-b332-4f13-98b1-1c9709e216bc")

    create(:live_edition, state: "published", base_path: "/published-and-draft-page", document: doc1, user_facing_version: 1)
    create(:edition, state: "draft", base_path: "/published-and-draft-page", document: doc1, user_facing_version: 2)
    create(:live_edition, state: "published", base_path: "/only-published-page", document: doc2)
    create(:superseded_edition, state: "superseded", base_path: "/superseded-and-draft-page", document: doc3, user_facing_version: 1)
    create(:edition, state: "draft", base_path: "/superseded-and-draft-page", document: doc3, user_facing_version: 2)

    unpublished1 = create(:live_edition, state: "published", base_path: "/redirected-from-page", document: doc4, user_facing_version: 1)
    unpublished1.unpublish(type: "redirect", redirects: [{ path: unpublished1.base_path, type: :exact, destination: "/redirected-to-page" }])

    unpublished2 = create(:live_edition, state: "published", base_path: "/gone-page", document: doc5, user_facing_version: 1)
    unpublished2.unpublish(type: "gone")

    unpublished3 = create(:live_edition, state: "published", base_path: "/withdrawn-page", document: doc6, user_facing_version: 1)
    unpublished3.unpublish(type: "withdrawal", explanation: "Consolidated into another page")

    create(:edition, state: "draft", base_path: "/only-draft-page", document: doc7, user_facing_version: 1)
  end

  def test_base_paths
    [
      "/published-and-draft-page",
      "/only-published-page",
      "/superseded-and-draft-page",
      "/does-not-exist",
      "/redirected-from-page",
      "/gone-page",
      "/withdrawn-page",
      "/only-draft-page",
    ]
  end
end
