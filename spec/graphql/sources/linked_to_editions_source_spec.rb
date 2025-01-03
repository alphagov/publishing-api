RSpec.describe Sources::LinkedToEditionsSource do
  it "returns the specified link set links" do
    source_document = create(:edition)
    target_document_1 = create(:edition)
    target_document_2 = create(:edition)
    target_document_3 = create(:edition)
    link_set = create(:link_set, content_id: source_document.content_id)
    create(:link, link_set: link_set, target_content_id: target_document_1.content_id, link_type: "test_link")
    create(:link, link_set: link_set, target_content_id: target_document_2.content_id, link_type: "another_link_type")
    create(:link, link_set: link_set, target_content_id: target_document_3.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, parent_object: source_document).request("test_link")

      expect(request.load).to eq([target_document_1, target_document_3])
    end
  end
end
