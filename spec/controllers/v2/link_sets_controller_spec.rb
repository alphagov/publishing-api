RSpec.describe V2::LinkSetsController do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id:) }

  before do
    create(:draft_edition, document:)
    stub_request(:any, /content-store/)
  end

  describe "bulk_links" do
    context "called without providing content_ids parameter" do
      it "is unsuccessful" do
        post :bulk_links, params: {}
        expect(response.status).to eql 422
      end
    end

    context "called with empty content_ids parameter" do
      it "is unsuccessful" do
        post :bulk_links, params: { content_ids: [] }
        expect(response.status).to eql 422
      end
    end

    context "with content_ids" do
      it "is successful" do
        post :bulk_links, params: { content_ids: [SecureRandom.uuid] }
        expect(response.status).to eql 200
      end
    end

    context "with over 1000 content_ids" do
      it "is unsuccessful" do
        content_id = SecureRandom.uuid
        content_ids = Array.new(1001) { content_id }
        post :bulk_links, params: { content_ids: }
        expect(response.status).to eql 413
      end
    end
  end

  describe "get_linked" do
    context "called without providing fields parameter" do
      it "is unsuccessful" do
        get :get_linked, params: { content_id:, link_type: "taxon" }
        expect(response.status).to eq(422)
      end
    end

    context "called with empty fields parameter" do
      it "is unsuccessful" do
        get :get_linked, params: { content_id:, link_type: "taxon", fields: [] }

        expect(response.status).to eq(422)
      end
    end

    context "called without providing link_type parameter" do
      before do
        get :get_linked, params: { content_id:, fields: %w[content_id] }
      end

      it "is unsuccessful" do
        expect(response.status).to eq(422)
      end
    end

    context "for an existing edition" do
      before do
        get :get_linked, params: { content_id:, link_type: "taxon", fields: %w[content_id] }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
    end

    context "for a non-existing edition" do
      before do
        get :get_linked, params: { content_id: SecureRandom.uuid, link_type: "taxon", fields: %w[content_id] }
      end

      it "is unsuccessful" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "patch_links" do
    let(:content_id) { SecureRandom.uuid }
    let(:payload) { { link_type: [SecureRandom.uuid] } }
    let(:subject) { patch :patch_links, params: { content_id: }, body: payload.to_json }

    context "when bulk_publishing is not set in the payload" do
      it "calls Commands::V2::PatchLinkSet with bulk_publishing set to false" do
        links_hash = payload.merge(
          bulk_publishing: false,
          content_id:,
        ).deep_symbolize_keys

        expect(Commands::V2::PatchLinkSet).to receive(:call).with(links_hash).and_call_original

        subject
      end
    end

    context "when bulk_publishing is set in the payload" do
      before do
        payload[:bulk_publishing] = true
      end

      it "calls Commands::V2::PatchLinkSet with bulk_publishing set to true" do
        links_hash = payload.merge(
          bulk_publishing: true,
          content_id:,
        ).deep_symbolize_keys

        expect(Commands::V2::PatchLinkSet).to receive(:call).with(links_hash).and_call_original

        subject
      end
    end
  end
end
