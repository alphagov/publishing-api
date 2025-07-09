RSpec.describe "Content Block Publication" do
  let(:content_block_document) { create(:document) }

  let!(:content_block_superseded_edition) { create(:edition, document: content_block_document, state: "superseded", content_store: nil, user_facing_version: 1) }
  let!(:content_block_live_edition) { create(:edition, document: content_block_document, state: "published", content_store: "live", user_facing_version: 2) }
  let(:content_block) { create(:draft_edition, update_type:, document: content_block_document, user_facing_version: 3) }

  let!(:change_note) { create(:change_note, note: "Some note goes here", edition: content_block, created_at: 1.day.ago) }

  let(:dependent_content) { create_list(:edition, 2, state: "published", content_store: "live") }

  let(:user_uuid) { SecureRandom.uuid }

  before do
    dependent_content.each do |item|
      item.links.create!({ link_type: "embed", target_content_id: content_block.content_id, created_at: 2.days.ago })
    end

    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  context "when the edition's update type is `major`" do
    let(:update_type) { "major" }

    it "sends the correct messages to the message queue for all dependent content" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                           .with(hash_including(content_id: content_block.content_id), event_type: "content_block")

      dependent_content.each do |item|
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                             .with(
                                                               expected_message(item),
                                                               event_type: "major",
                                                             )
      end

      post "/v2/content/#{content_block.content_id}/publish",
           params: {
             update_type: "content_block",
           }.to_json,
           headers: {
             "X-GOVUK-AUTHENTICATED-USER" => user_uuid,
           }

      expect(response).to be_ok, response.body
    end
  end

  context "when the edition's update type is `minor`" do
    let(:update_type) { "minor" }

    it "sends the correct messages to the message queue for all dependent content" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                           .with(hash_including(content_id: content_block.content_id), event_type: "content_block")

      dependent_content.each do |item|
        expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                             .with(
                                                               expected_message(item),
                                                               event_type: "minor",
                                                             )
      end

      post "/v2/content/#{content_block.content_id}/publish",
           params: {
             update_type: "content_block",
           }.to_json,
           headers: {
             "X-GOVUK-AUTHENTICATED-USER" => user_uuid,
           }

      expect(response).to be_ok, response.body
    end
  end

  def expected_message(item)
    hash_including(
      content_id: item.content_id,
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
