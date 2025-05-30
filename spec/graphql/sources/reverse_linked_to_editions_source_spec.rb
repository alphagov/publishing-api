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
      request = dataloader.with(
        described_class,
        content_store: target_edition.content_store,
        locale: "en",
      ).request([target_edition, "test_link"])

      expect(request.load).to eq([source_edition_1, source_edition_3])
    end
  end

  it "returns the specified reverse edition links" do
    target_edition = create(:edition)

    source_edition_1 = create(:edition,
                              links_hash: {
                                "test_link" => [target_edition.content_id],
                              })

    source_edition_2 = create(:edition,
                              links_hash: {
                                "test_link" => [target_edition.content_id],
                              })

    create(:edition,
           links_hash: {
             "another_link_type" => [target_edition.content_id],
           })

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: target_edition.content_store,
        locale: "en",
      ).request([target_edition, "test_link"])

      expect(request.load).to eq([source_edition_1, source_edition_2])
    end
  end

  context "when the linked item is unpublished" do
    %w[children parent related_statistical_data_sets].each do |link_type|
      it "includes unpublished links when they are of the permitted type #{link_type}" do
        target_edition = create(:edition, content_store: "live")

        link_set_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")
        link_set = create(:link_set, content_id: link_set_linked_edition.content_id)
        create(:link, link_set:, target_content_id: target_edition.content_id, link_type:)

        edition_linked_edition = create(:withdrawn_unpublished_edition,
                                        content_store: "live",
                                        links_hash: {
                                          link_type => [target_edition.content_id],
                                        })

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "en",
          ).request([target_edition, link_type])

          expect(request.load).to eq([link_set_linked_edition, edition_linked_edition])
        end
      end
    end

    it "does not include unpublished links when they are of another type" do
      target_edition = create(:edition, content_store: "live")

      link_set_linked_edition = create(:withdrawn_unpublished_edition, content_store: "live")
      link_set = create(:link_set, content_id: link_set_linked_edition.content_id)
      create(:link, link_set:, target_content_id: target_edition.content_id, link_type: "test_link")

      create(:withdrawn_unpublished_edition,
             content_store: "live",
             links_hash: {
               "test_link" => [target_edition.content_id],
             })

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "test_link"])

        expect(request.load).to eq([])
      end
    end
  end

  describe "links between documents with different locales" do
    it "fetches reverse links matching the specified locale" do
      target_edition = create(:edition)

      content_id_1 = SecureRandom.uuid
      _edition_1_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_1),
        links_hash: { "edition_link" => [target_edition.content_id] },
      )
      edition_1_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_1),
        links_hash: { "edition_link" => [target_edition.content_id] },
      )

      content_id_2 = SecureRandom.uuid
      _edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      create(
        :link_set,
        content_id: content_id_2,
        links_hash: { "link_set_link" => [target_edition.content_id] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request_1 = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "fr",
        ).request([target_edition, "edition_link"])

        request_2 = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "fr",
        ).request([target_edition, "link_set_link"])

        expect(request_1.load).to match_array([edition_1_fr])
        expect(request_2.load).to match_array([edition_2_fr])
      end
    end

    it "returns English language reverse links if there's no better match available" do
      target_edition = create(:edition)

      content_id_1 = SecureRandom.uuid
      edition_1_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_1),
        links_hash: { "edition_link" => [target_edition.content_id] },
      )
      _edition_1_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_1),
        links_hash: { "edition_link" => [target_edition.content_id] },
      )

      content_id_2 = SecureRandom.uuid
      edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      _edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      create(
        :link_set,
        content_id: content_id_2,
        links_hash: { "link_set_link" => [target_edition.content_id] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request_1 = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "de",
        ).request([target_edition, "edition_link"])

        request_2 = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "de",
        ).request([target_edition, "link_set_link"])

        expect(request_1.load).to match_array([edition_1_en])
        expect(request_2.load).to match_array([edition_2_en])
      end
    end
  end
end
