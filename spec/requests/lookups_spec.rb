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
    it "returns content_ids for user-visible states (published, unpublished)" do
      create_test_content

      post "/lookup-by-base-path", params: { base_paths: test_base_paths }

      expect(parsed_response).to eql(
        "/published-and-draft-page" => "aa491126-77ed-4e81-91fa-8dc7f74e9657",
        "/only-published-page" => "bbabcd3c-7c45-4403-8490-db51e4bfc4f6",
      )
    end
  end

  context "passing included parameter" do
    it "returns content_ids for user-visible states (published, unpublished)" do
      create_test_content

      post "/lookup-by-base-path", params: { base_paths: test_base_paths, include: ["published"] }

      expect(parsed_response).to eql(
        "published" => {
          "/published-and-draft-page" => "aa491126-77ed-4e81-91fa-8dc7f74e9657",
          "/only-published-page" => "bbabcd3c-7c45-4403-8490-db51e4bfc4f6",
        }
      )
    end

    it "returns content_ids for unpublished and redirected base paths" do
      create_test_content

      post "/lookup-by-base-path", params: { base_paths: test_base_paths, include: ["redirected"] }

      expect(parsed_response).to eql(
        "redirected" => {
          "/original-base-path" => "/new-base-path",
        }
      )
    end
  end

  def create_test_content
    doc1 = FactoryGirl.create(:document, content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")
    doc2 = FactoryGirl.create(:document, content_id: "bbabcd3c-7c45-4403-8490-db51e4bfc4f6")
    doc3 = FactoryGirl.create(:document, content_id: "dd1bf833-f91c-4e45-9f97-87b165808176")

    FactoryGirl.create(:live_edition, state: "published", base_path: "/published-and-draft-page", document: doc1, user_facing_version: 1)
    FactoryGirl.create(:edition, state: "draft", base_path: "/published-and-draft-page", document: doc1, user_facing_version: 2)
    FactoryGirl.create(:live_edition, state: "published", base_path: "/only-published-page", document: doc2)
    FactoryGirl.create(:edition, state: "draft", base_path: "/draft-and-superseded-page", document: doc3, user_facing_version: 2)
    FactoryGirl.create(:superseded_edition, state: "superseded", base_path: "/draft-and-superseded-page", document: doc3, user_facing_version: 1)

    create_unpublished_content
  end

  def create_unpublished_content
    doc1 = FactoryGirl.create(:document, content_id: "ee491126-77ed-4e81-91fa-8dc7f74e9657")
    doc2 = FactoryGirl.create(:document, content_id: "ffabcd3c-7c45-4403-8490-db51e4bfc4f6")

    published1 = FactoryGirl.create(:live_edition, state: "published", base_path: "/original-base-path", document: doc1, user_facing_version: 1)
    published1.unpublish(type: "redirect", alternative_path: "/new-base-path")

    published2 = FactoryGirl.create(:live_edition, state: "published", base_path: "/gone-page", document: doc2, user_facing_version: 1)
    published2.unpublish(type: "gone")

  end

  def test_base_paths
    ["/published-and-draft-page", "/only-published-page", "/draft-and-superseded-page", "/does-not-exist", "/original-base-path", "/gone-page"]
  end
end
