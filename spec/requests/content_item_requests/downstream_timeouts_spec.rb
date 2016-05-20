require "rails_helper"

RSpec.describe "Downstream timeouts", type: :request do
  context "/content" do
    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/content#{base_path}", content_item_params.to_json

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
        put "/content#{base_path}", content_item_params.to_json

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

  context "/draft-content" do
    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/draft-content#{base_path}", content_item_params.to_json

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

  context "/v2/content" do
    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/v2/content/#{content_id}", v2_content_item.to_json

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
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :patch }

    before do
      FactoryGirl.create(:live_content_item, v2_content_item.slice(*ContentItem::TOP_LEVEL_FIELDS))
      draft = FactoryGirl.create(:draft_content_item, v2_content_item.slice(*ContentItem::TOP_LEVEL_FIELDS))

      FactoryGirl.create(:access_limit,
        content_item: draft,
        users: access_limit_params.fetch(:users),
      )
    end

    context "draft content store times out" do
      before do
        stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        put "/v2/links/#{content_id}", links_attributes.to_json

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
        put "/v2/links/#{content_id}", links_attributes.to_json

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
