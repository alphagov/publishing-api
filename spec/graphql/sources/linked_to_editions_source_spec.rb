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
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
        locale: "en",
      ).request([source_edition, "test_link"])

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
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
        locale: "en",
      ).request([source_edition, "test_link"])

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
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
        locale: "en",
      ).request([source_edition, "test_link"])

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
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
        locale: "en",
      ).request([source_edition, "test_link"])

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
        locale: "en",
      ).request([
        source_edition,
        "test_link",
        %i[id base_path title document_id],
      ])

      expect(request.load).to eq([target_edition_0, target_edition_1, target_edition_2, target_edition_3])
    end
  end

  context "when the linked item is unpublished" do
    %w[children parent related_statistical_data_sets].each do |link_type|
      it "includes unpublished links when they are of the permitted type #{link_type}" do
        edition_linked_edition = create(:edition, content_store: "live")
        withdrawn_edition_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")
        link_set_linked_edition = create(:edition, content_store: "live")
        withdrawn_link_set_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")

        source_edition = create(:edition,
                                content_store: "live",
                                links_hash: {
                                  link_type => [edition_linked_edition.content_id, withdrawn_edition_linked_edition.content_id],
                                })

        link_set = create(:link_set, content_id: source_edition.content_id)
        create(:link, link_set:, target_content_id: link_set_linked_edition.content_id, link_type:)
        create(:link, link_set:, target_content_id: withdrawn_link_set_linked_edition.content_id, link_type:)

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "en",
          ).request([source_edition, link_type])

          expect(request.load).to match_array([edition_linked_edition, withdrawn_edition_linked_edition, link_set_linked_edition, withdrawn_link_set_linked_edition])
        end
      end
    end

    it "does not include unpublished links when they are of another type" do
      edition_linked_edition = create(:edition, content_store: "live")
      withdrawn_edition_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")
      link_set_linked_edition = create(:edition, content_store: "live")
      withdrawn_link_set_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")

      source_edition = create(:edition,
                              content_store: "live",
                              links_hash: {
                                "test_link" => [edition_linked_edition.content_id, withdrawn_edition_linked_edition.content_id],
                              })

      link_set = create(:link_set, content_id: source_edition.content_id)
      create(:link, link_set:, target_content_id: link_set_linked_edition.content_id, link_type: "test_link")
      create(:link, link_set:, target_content_id: withdrawn_link_set_linked_edition.content_id, link_type: "test_link")

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "en",
        ).request([source_edition, "test_link"])

        expect(request.load).to match_array([edition_linked_edition, link_set_linked_edition])
      end
    end
  end

  describe "links between documents with different locales" do
    it "fetches links matching the specified locale" do
      content_id_1 = SecureRandom.uuid
      _edition_1_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_1))
      edition_1_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1))

      content_id_2 = SecureRandom.uuid
      _edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      source_edition = create(
        :edition,
        links_hash: { "edition_link" => [content_id_1] },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: { "link_set_link" => [content_id_2] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request_1 = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "fr",
        ).request([source_edition, "edition_link"])

        request_2 = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "fr",
        ).request([source_edition, "link_set_link"])

        expect(request_1.load).to match_array([edition_1_fr])
        expect(request_2.load).to match_array([edition_2_fr])
      end
    end

    it "returns English language links if there's no better match available" do
      content_id_1 = SecureRandom.uuid
      edition_1_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_1))
      _edition_1_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1))

      content_id_2 = SecureRandom.uuid
      edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      _edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      source_edition = create(
        :edition,
        links_hash: { "edition_link" => [content_id_1] },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: { "link_set_link" => [content_id_2] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request_1 = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "de",
        ).request([source_edition, "edition_link"])

        request_2 = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "de",
        ).request([source_edition, "link_set_link"])

        expect(request_1.load).to match_array([edition_1_en])
        expect(request_2.load).to match_array([edition_2_en])
      end
    end
  end
end
