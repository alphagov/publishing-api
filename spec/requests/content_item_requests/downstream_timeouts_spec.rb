require "rails_helper"

RSpec.describe "Downstream timeouts", type: :request do
  context "/v2/content" do
    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/v2/content/#{content_id}", params: v2_content_item.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: GdsApi::TimedOutException"
          }
        )
      end
    end
  end

  context "/v2/links" do
    let(:request_body) { patch_links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :patch }
    let(:base_path) { "/vat-rates" }

    before do
      document = create(:document, content_id: content_id)

      create(:live_edition,
        v2_content_item
          .slice(*Edition::TOP_LEVEL_FIELDS)
          .merge(base_path: base_path, user_facing_version: 1, document: document))

      draft = create(:draft_edition,
        v2_content_item
          .slice(*Edition::TOP_LEVEL_FIELDS)
          .merge(base_path: base_path, user_facing_version: 2, document: document))

      create(:access_limit,
        edition: draft,
        users: access_limit_params.fetch(:users))
    end

    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: GdsApi::TimedOutException"
          }
        )
      end
    end

    context "content store times out" do
      before do
        stub_request(:put, Plek.find('content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/v2/links/#{content_id}", params: patch_links_attributes.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: GdsApi::TimedOutException"
          }
        )
      end
    end
  end
end
