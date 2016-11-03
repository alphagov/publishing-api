require "rails_helper"

RSpec.describe V2::ActionsController do
  describe ".create" do
    let(:content_id) { SecureRandom.uuid }
    let(:locale) { "en" }
    let(:action) { "FactCheck" }

    let(:params) { { content_id: content_id, format: :json } }
    let(:payload) do
      {
        locale: locale,
        action: action,
      }
    end
    let(:json_payload) { payload.to_json }

    context "when a content item exists" do
      before do
        FactoryGirl.create(
          :draft_content_item,
          content_id: content_id,
          locale: locale,
          lock_version: 5
        )
      end

      context "and the request is valid" do
        it "returns 201" do
          post(:create, params: params, body: json_payload)
          expect(response).to have_http_status(201)
        end
      end

      context "and the request has an empty action" do
        let(:action) { nil }

        it "returns 422" do
          post(:create, params: params, body: json_payload)
          expect(response).to have_http_status(422)
        end
      end

      context "and an old version is requested" do
        before { payload.merge!(previous_version: 6) }

        it "returns 409" do
          post(:create, params: params, body: json_payload)
          expect(response).to have_http_status(409)
        end
      end
    end

    context "when the content item does not exist" do
      it "returns 404" do
        post(:create, params: params, body: json_payload)
        expect(response).to have_http_status(404)
      end
    end
  end
end
