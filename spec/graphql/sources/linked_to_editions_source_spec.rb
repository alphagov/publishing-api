RSpec.describe Sources::LinkedToEditionsSource do
  it "returns the specified link set links" do
    source_edition = create(:edition)
    target_edition_1 = create(:edition)
    target_edition_2 = create(:edition)
    target_edition_3 = create(:edition)
    link_set = create(:link_set, content_id: source_edition.content_id)
    create(:link, link_set: link_set, target_content_id: target_edition_1.content_id, link_type: "test_link")
    create(:link, link_set: link_set, target_content_id: target_edition_2.content_id, link_type: "another_link_type")
    create(:link, link_set: link_set, target_content_id: target_edition_3.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, content_store: source_edition.content_store).request([source_edition, "test_link"])

      expect(request.load).to match_array([target_edition_1, target_edition_3])
    end
  end

  it "returns the specified edition links" do
    target_edition_1 = create(:edition)
    target_edition_2 = create(:edition)
    target_edition_3 = create(:edition)

    source_edition = create(:edition,
                            links_hash: {
                              "test_link" => [target_edition_1.content_id, target_edition_3.content_id],
                              "another_link_type" => [target_edition_2.content_id],
                            })

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, content_store: source_edition.content_store).request([source_edition, "test_link"])

      expect(request.load).to match_array([target_edition_1, target_edition_3])
    end
  end

  it "returns a mixture of links when both present" do
    target_edition_1 = create(:edition)
    target_edition_2 = create(:edition)
    target_edition_3 = create(:edition)

    source_edition = create(:edition,
                            links_hash: {
                              "test_link" => [target_edition_1.content_id],
                              "another_link_type" => [target_edition_2.content_id],
                            })

    link_set = create(:link_set, content_id: source_edition.content_id)
    create(:link, link_set: link_set, target_content_id: target_edition_3.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, content_store: source_edition.content_store).request([source_edition, "test_link"])

      expect(request.load).to match_array([target_edition_1, target_edition_3])
    end
  end

  it "returns links from only the requested content store" do
    target_edition_1 = create(:edition, content_store: "live")
    target_edition_2 = create(:edition, content_store: "live")
    target_edition_3 = create(:edition, content_store: "draft")
    target_edition_4 = create(:edition, content_store: "draft")

    source_edition = create(:edition,
                            content_store: "draft",
                            links_hash: {
                              "test_link" => [target_edition_1.content_id, target_edition_3.content_id],
                            })

    link_set = create(:link_set, content_id: source_edition.content_id)
    create(:link, link_set:, target_content_id: target_edition_2.content_id, link_type: "test_link")
    create(:link, link_set:, target_content_id: target_edition_4.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(described_class, content_store: source_edition.content_store).request([source_edition, "test_link"])

      expect(request.load).to match_array([target_edition_3, target_edition_4])
    end
  end

  it "returns editions in order of their associated link's `position`" do
    target_edition_0 = create(:edition)
    target_edition_1 = create(:edition)
    target_edition_2 = create(:edition)
    target_edition_3 = create(:edition)

    source_edition = create(:edition, content_store: "draft")
    create(:link, edition: source_edition, target_content_id: target_edition_1.content_id, position: 1, link_type: "test_link")
    create(:link, edition: source_edition, target_content_id: target_edition_3.content_id, position: 3, link_type: "test_link")

    link_set = create(:link_set, content_id: source_edition.content_id)
    create(:link, link_set:, target_content_id: target_edition_0.content_id, position: 0, link_type: "test_link")
    create(:link, link_set:, target_content_id: target_edition_2.content_id, position: 2, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
      ).request([
        source_edition,
        "test_link",
        %i[id base_path title document_id],
      ])

      expect(request.load).to eq([target_edition_0, target_edition_1, target_edition_2, target_edition_3])
    end
  end
end
