RSpec.describe "Content Block Publication" do
  let(:content_block) { create(:draft_edition) }
  let(:dependent_content) { create_list(:edition, 2, state: "published", content_store: "live") }
  let!(:change_note) { create(:change_note, note: "Some note goes here", edition: content_block) }
  let(:user_uuid) { SecureRandom.uuid }

  before do
    dependent_content.each do |item|
      item.links.create!({ link_type: "embed", target_content_id: content_block.content_id })
    end

    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  it "sends the correct messages to the message queue for all dependent content" do
    expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                         .with(hash_including(content_id: content_block.content_id), event_type: "content_block")

    dependent_content.each do |item|
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
                                                           .with(
                                                             hash_including(
                                                               content_id: item.content_id,
                                                               source_block: {
                                                                 "title" => content_block.title,
                                                                 "content_id" => content_block.content_id,
                                                                 "document_type" => content_block.document_type,
                                                                 "updated_by_user_uid" => user_uuid,
                                                                 "update_type" => content_block.update_type,
                                                                 "change_note" => change_note.note,
                                                               },
                                                             ),
                                                             event_type: "host_content",
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
