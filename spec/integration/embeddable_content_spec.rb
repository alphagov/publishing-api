RSpec.describe "Publishing changes to embeddable content" do
  EmbeddedContentFinderService::SUPPORTED_DOCUMENT_TYPES.each do |document_type|
    context "with a #{document_type} document type" do
      let(:document) { create(:document) }
      let!(:live_embeddable_edition) { create(:live_edition, document_type:, document:) }
      let!(:draft_embeddable_edition) { create(:draft_edition, user_facing_version: 2, document_type:, document:) }

      let(:editions) { create_list(:edition, 2, state: "published", content_store: "live") }

      before do
        stub_request(:put, %r{.*content-store.*/content/.*})
        allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)

        editions.each do |edition|
          edition.links.create!(
            { link_type: "embed", target_content_id: document.content_id },
          )
        end
      end

      it "creates a `major` event message and creates a change note for all dependent content" do
        post "/v2/content/#{document.content_id}/publish", params: { locale: "en", update_type: "major" }.to_json

        editions.each do |edition|
          expect(PublishingAPI.service(:queue_publisher)).to have_received(:send_message).with(
            a_hash_including({ content_id: edition.content_id, details: a_hash_including({ change_history: [a_hash_including(note: "#{live_embeddable_edition.document_type.titleize} #{live_embeddable_edition.title} changed")] }) }),
            { event_type: "major" },
          )
        end
      end
    end
  end
end
