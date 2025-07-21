RSpec.describe "Content Block Publish" do
  let(:content_block_document) { create(:document) }

  let(:document_type) { "content_block_pension" }
  let!(:content_block_superseded_edition) { create(:edition, document: content_block_document, state: "superseded", content_store: nil, user_facing_version: 1, document_type:) }
  let!(:content_block_live_edition) { create(:edition, document: content_block_document, state: "published", content_store: "live", user_facing_version: 2, document_type:) }
  let(:content_block) { create(:draft_edition, update_type:, document: content_block_document, user_facing_version: 3, document_type:, public_updated_at: 1.minute.ago) }

  let!(:change_note) { create(:change_note, note: "Some note goes here", edition: content_block, created_at: 1.day.ago) }

  let(:editions_with_content_blocks) { create_list(:edition, 2, state: "published", content_store: "live", public_updated_at: 5.days.ago) }

  let(:user_uuid) { SecureRandom.uuid }

  before do
    editions_with_content_blocks.each do |item|
      item.links.create!({ link_type: "embed", target_content_id: content_block.content_id, created_at: 2.days.ago })
    end

    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  context "when the edition's update type is `major`" do
    let(:update_type) { "major" }

    it "sends details of the embedded content changes made to editions with content blocks" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                           .with(hash_including(content_id: content_block.content_id), event_type: "major")

      editions_with_content_blocks.each do |item|
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                             .with(
                                                               expected_message(item),
                                                               event_type: "major",
                                                             )
      end

      post "/v2/content/#{content_block.content_id}/publish",
           params: {}.to_json,
           headers: {
             "X-GOVUK-AUTHENTICATED-USER" => user_uuid,
           }

      expect(response).to be_ok, response.body
    end
  end

  context "when the edition's update type is `minor`" do
    let(:update_type) { "minor" }

    it "should not send the change history payload to the queue" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                           .with(hash_including(content_id: content_block.content_id), event_type: "minor")

      editions_with_content_blocks.each do |item|
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
                                                             .with(
                                                               expected_message(item),
                                                               event_type: anything,
                                                             )
      end

      post "/v2/content/#{content_block.content_id}/publish",
           params: {}.to_json,
           headers: {
             "X-GOVUK-AUTHENTICATED-USER" => user_uuid,
           }

      expect(response).to be_ok, response.body
    end
  end

  def expected_message(item)
    hash_including(
      content_id: item.content_id,
      public_updated_at: content_block.to_h[:public_updated_at],
      details: hash_including(
        change_history: array_including(
          hash_including(
            note: change_note.note,
          ),
        ),
      ),
    )
  end
end
