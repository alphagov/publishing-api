RSpec.describe "PUT /v2/content when the 'links' parameter is provided" do
  include_context "PutContent call"

  before do
    payload.merge!(links: { policy_areas: [link] })
  end

  context "invalid UUID" do
    let!(:link) { "not a UUID" }

    it "should raise a validation error" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(response.status).to eq(422)
      expect(response.body).to match(/UUID/)
    end
  end

  context "valid UUID" do
    let(:document) { create(:document) }
    let!(:link) { document.content_id }

    it "should create a link" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(1)

      expect(Link.find_by(target_content_id: document.content_id)).to be
    end
  end

  context "existing links" do
    let(:document) { create(:document, content_id:) }
    let(:content_id) { SecureRandom.uuid }
    let(:link) { SecureRandom.uuid }

    before do
      edition.links.create!(target_content_id: document.content_id, link_type: "policy_areas")
    end

    context "draft edition" do
      let(:edition) { create(:draft_edition, document:, base_path:) }

      it "passes the old link to dependency resolution" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).with(
          "downstream_high",
          a_hash_including(orphaned_content_ids: [content_id]),
        )
        put "/v2/content/#{content_id}", params: payload.to_json
      end
    end

    context "published edition" do
      let(:edition) { create(:live_edition, document:, base_path:) }

      it "passes the old link to dependency resolution" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).with(
          "downstream_high",
          a_hash_including(orphaned_content_ids: [content_id]),
        )
        put "/v2/content/#{content_id}", params: payload.to_json
      end
    end
  end
end
