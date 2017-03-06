require "rails_helper"

RSpec.describe "/v2/lookup-by-base-path", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/document" }
  let(:document) { FactoryGirl.create(:document, content_id: content_id) }

  before do
    FactoryGirl.create(:draft_edition, document: document, base_path: base_path)
  end

  context "GET" do
    it "requires a base path param" do
      expected_error_response = { "error" => { "code" => 422, "message" => "param is missing or the value is empty: base_paths" } }

      get "/v2/lookup-by-base-path"

      expect(parsed_response).to eq(expected_error_response)
    end

    it "rejects requests with more than 100 base paths" do
      base_paths = 1.upto(101).map { |i| "/foo-#{i}" }

      get v2_lookup_by_base_path_path, params: { base_paths: base_paths }

      expected_error_response = { "error" => { "code" => 400, "message" => "base_paths must contain less than 100 items" } }
      expect(parsed_response).to eq(expected_error_response)
    end

    it "queries content matching the base_paths" do
      get v2_lookup_by_base_path_path, params: { base_paths: [base_path] }

      expect(response.status).to eq(200)
      expect(parsed_response.keys).to eq([base_path])

      parsed_content_id = parsed_response.dig(
        base_path,
        "draft",
        "content_id"
      )

      expect(parsed_content_id).to eq(content_id)
    end
  end

  context "called with POST" do
    it "requires a base path param" do
      expected_error_response = { "error" => { "code" => 422, "message" => "param is missing or the value is empty: base_paths" } }

      post "/v2/lookup-by-base-path"

      expect(parsed_response).to eq(expected_error_response)
    end

    it "queries content matching the base_paths" do
      post v2_lookup_by_base_path_path, params: { base_paths: [base_path] }

      expect(response.status).to eq(200)
      expect(parsed_response.keys).to eq([base_path])

      parsed_content_id = parsed_response.dig(
        base_path,
        "draft",
        "content_id"
      )

      expect(parsed_content_id).to eq(content_id)
    end
  end
end
