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

      post "/lookup-by-base-path", base_paths: test_base_paths

      expect(parsed_response).to eql(
        "/published-and-draft-page" => "aa491126-77ed-4e81-91fa-8dc7f74e9657",
        "/only-published-page" => "bbabcd3c-7c45-4403-8490-db51e4bfc4f6",
        "/only-unpublished-page" => "cc6d416c-f369-4b7c-bac7-5e9401e79362",
      )
    end

    it "ignored redirects" do
      FactoryGirl.create(:redirect_content_item, state: "unpublished", base_path: "/published-page", content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")
      base_paths = ['/published-page']

      post "/lookup-by-base-path", base_paths: base_paths

      expect(parsed_response).to eql({})
    end
  end

  def create_test_content
    FactoryGirl.create(:content_item, state: "published", base_path: "/published-and-draft-page", content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")
    FactoryGirl.create(:content_item, state: "draft", base_path: "/published-and-draft-page", content_id: "aa491126-77ed-4e81-91fa-8dc7f74e9657")
    FactoryGirl.create(:content_item, state: "published", base_path: "/only-published-page", content_id: "bbabcd3c-7c45-4403-8490-db51e4bfc4f6")
    FactoryGirl.create(:content_item, state: "unpublished", base_path: "/only-unpublished-page", content_id: "cc6d416c-f369-4b7c-bac7-5e9401e79362")
    FactoryGirl.create(:content_item, state: "draft", base_path: "/draft-and-superseded-page", content_id: "dd1bf833-f91c-4e45-9f97-87b165808176")
    FactoryGirl.create(:content_item, state: "superseded", base_path: "/draft-and-superseded-page", content_id: "dd1bf833-f91c-4e45-9f97-87b165808176")
  end

  def test_base_paths
    ["/published-and-draft-page", "/only-published-page", "/only-unpublished-page", "/draft-and-superseded-page", "/does-not-exist"]
  end
end
