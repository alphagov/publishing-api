require "rails_helper"

RSpec.describe V2::LinkSetsController do
  let(:content_id) { SecureRandom.uuid }

  before do
    create(:draft_content_item, content_id: content_id)
    stub_request(:any, /content-store/)
  end

  describe "get_linked" do
    context "called without providing fields parameter" do
      it "is unsuccessful" do
        get :get_linked, {
          content_id: content_id,
          link_type: "topic",
        }

        expect(response.status).to eq(422)
      end
    end

    context "called with empty fields parameter" do
      it "is unsuccessful" do
        get :get_linked,           content_id: content_id,
          link_type: "topic",
          fields: []

        expect(response.status).to eq(422)
      end
    end

    context "called without providing link_type parameter" do
      before do
        get :get_linked,           content_id: content_id,
          fields: ["content_id"]
      end

      it "is unsuccessful" do
        expect(response.status).to eq(422)
      end
    end

    context "for an existing content item" do
      before do
        get :get_linked,           content_id: content_id,
          link_type: "topic",
          fields: ["content_id"]
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
    end

    context "for a non-existing content item" do
      before do
        get :get_linked,           content_id: SecureRandom.uuid,
          link_type: "topic",
          fields: ["content_id"]
      end

      it "is unsuccessful" do
        expect(response.status).to eq(404)
      end
    end
  end
end
