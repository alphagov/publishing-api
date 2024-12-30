RSpec.describe Sources::ReverseLinkedToEditionsSource do
  it "returns the specified reverse link set links" do
    target_edition = create(:edition)
    source_edition_1 = create(:edition)
    source_edition_2 = create(:edition)
    source_edition_3 = create(:edition)
    link_set_1 = create(:link_set, content_id: source_edition_1.content_id)
    link_set_2 = create(:link_set, content_id: source_edition_2.content_id)
    link_set_3 = create(:link_set, content_id: source_edition_3.content_id)
    create(:link, link_set: link_set_1, target_content_id: target_edition.content_id, link_type: "test_link")
    create(:link, link_set: link_set_2, target_content_id: target_edition.content_id, link_type: "another_link_type")
    create(:link, link_set: link_set_3, target_content_id: target_edition.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, parent_object: target_edition).request("test_link")

      expect(request.load).to eq([source_edition_1, source_edition_3])
    end
  end
end
