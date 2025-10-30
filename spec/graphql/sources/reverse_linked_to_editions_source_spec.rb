RSpec.describe Sources::ReverseLinkedToEditionsSource do
  it "returns the specified reverse link set links" do
    target_edition = create(:edition)
    source_edition_1 = create(:edition, title: "edition 1, test link")
    source_edition_2 = create(:edition, title: "edition 2, another link type")
    source_edition_3 = create(:edition, title: "edition 3, test link")
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

      actual_titles = request.load.map(&:title)
      expected_titles = [source_edition_1, source_edition_3].map(&:title)
      expect(actual_titles).to match_array(expected_titles)
    end
  end

  it "returns the specified reverse edition links" do
    target_edition = create(:edition)

    source_edition_1 = create(:edition,
                              title: "edition 1, test link",
                              links_hash: {
                                "test_link" => [target_edition.content_id],
                              })

    source_edition_2 = create(:edition,
                              title: "edition 2, test link",
                              links_hash: {
                                "test_link" => [target_edition.content_id],
                              })

    create(:edition,
           title: "edition 3, another link type",
           links_hash: {
             "another_link_type" => [target_edition.content_id],
           })

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: target_edition.content_store,
        locale: "en",
      ).request([target_edition, "test_link"])

      actual_titles = request.load.map(&:title)
      expected_titles = [source_edition_1, source_edition_2].map(&:title)
      expect(actual_titles).to match_array(expected_titles)
    end
  end

  it "returns editions ordered by their reverse links' `position`" do
    target_edition = create(:edition)

    source_edition_0 = create(:edition, title: "edition 0, link set 0, position 0")
    source_edition_1 = create(:edition, title: "edition 1, link set 1, position 1")
    source_edition_2 = create(:edition, title: "edition 2, edition link, position 2")

    link_set_0 = create(:link_set, content_id: source_edition_0.content_id)
    link_set_1 = create(:link_set, content_id: source_edition_1.content_id)

    create(:link, position: 0, link_set: link_set_0, target_content_id: target_edition.content_id, link_type: "test_link")
    create(:link, position: 2, edition: source_edition_2, target_content_id: target_edition.content_id, link_type: "test_link")
    create(:link, position: 1, link_set: link_set_1, target_content_id: target_edition.content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: target_edition.content_store,
        locale: "en",
      ).request([target_edition, "test_link"])

      actual_titles = request.load.map(&:title)
      expected_titles = [source_edition_0, source_edition_1, source_edition_2].map(&:title)
      expect(actual_titles).to match_array(expected_titles)
    end
  end

  context "when reverse links have the same `position`" do
    it "returns editions reverse-ordered by their associated reverse links' `id`" do
      target_edition = create(:edition)

      source_edition_1 = create(:edition, title: "edition 1, link set link, second link id")
      source_edition_0 = create(:edition, title: "edition 0, link set link, first link id")
      source_edition_2 = create(:edition, title: "edition 2, edition link, third link id")

      link_set_0 = create(:link_set, content_id: source_edition_0.content_id)
      link_set_1 = create(:link_set, content_id: source_edition_1.content_id)

      create(:link, position: 0, link_set: link_set_0, target_content_id: target_edition.content_id, link_type: "test_link")
      create(:link, position: 0, link_set: link_set_1, target_content_id: target_edition.content_id, link_type: "test_link")
      create(:link, position: 0, edition: source_edition_2, target_content_id: target_edition.content_id, link_type: "test_link")

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expected_titles = [source_edition_2, source_edition_1, source_edition_0].map(&:title)
        expect(actual_titles).to eq(expected_titles)
      end
    end
  end

  context "when the same document is both a link set link and an edition link" do
    it "only returns the document once" do
      target_edition = create(:edition)

      source_edition = create(:edition,
                              links_hash: {
                                "test_link" => [target_edition.content_id],
                              })

      link_set = create(:link_set, content_id: source_edition.content_id)
      create(:link, link_set: link_set, target_content_id: target_edition.content_id, link_type: "test_link")

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "test_link"])

        expect(request.load).to eq([source_edition])
      end
    end
  end

  context "when the linked item is unpublished" do
    it "includes unpublished links when they are of a permitted type" do
      target_edition = create(:edition, content_store: "live")

      link_set_linked_edition = create(
        :withdrawn_unpublished_edition,
        content_store: "live",
        title: "edition 1, withdrawn, link set link, parent link",
      )
      link_set = create(:link_set, content_id: link_set_linked_edition.content_id)
      create(:link, link_set:, target_content_id: target_edition.content_id, link_type: "parent")

      edition_linked_edition = create(:withdrawn_unpublished_edition,
                                      content_store: "live",
                                      title: "edition 2, withdrawn, edition link, parent link",
                                      links_hash: {
                                        "parent" => [target_edition.content_id],
                                      })

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "parent"])

        actual_titles = request.load.map(&:title)
        expected_titles = [link_set_linked_edition, edition_linked_edition].map(&:title)
        expect(actual_titles).to match_array(expected_titles)
      end
    end

    it "does not include unpublished links when they are of another type" do
      target_edition = create(:edition, content_store: "live")

      link_set_linked_edition = create(
        :withdrawn_unpublished_edition,
        content_store: "live",
        title: "edition 0, withdrawn, link set link, test_link link",
      )
      link_set = create(:link_set, content_id: link_set_linked_edition.content_id)
      create(:link, link_set:, target_content_id: target_edition.content_id, link_type: "test_link")

      create(:withdrawn_unpublished_edition,
             content_store: "live",
             title: "edition 0, withdrawn, edition link, test_link link",
             links_hash: {
               "test_link" => [target_edition.content_id],
             })

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expect(actual_titles).to eq([])
      end
    end
  end

  it "doesn't include non-renderable reverse links" do
    target_edition = create(:edition)

    renderable_edition_1 = create(
      :edition,
      links_hash: { "test_link" => [target_edition.content_id] },
      title: "renderable edition 1, edition link",
    )
    create(
      :redirect_edition,
      links_hash: { "test_link" => [target_edition.content_id] },
      title: "non-renderable edition (redirect)",
    )

    renderable_edition_2 = create(:edition, title: "renderable edition 2, link set link")
    create(
      :link_set,
      content_id: renderable_edition_2.content_id,
      links_hash: { "test_link" => [target_edition.content_id] },
    )
    non_renderable_edition = create(:gone_edition, title: "non-renderable edition (gone)")
    create(
      :link_set,
      content_id: non_renderable_edition.content_id,
      links_hash: { "test_link" => [target_edition.content_id] },
    )

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: target_edition.content_store,
        locale: "en",
      ).request([target_edition, "test_link"])

      actual_titles = request.load.map(&:title)
      expected_titles = [renderable_edition_1, renderable_edition_2].map(&:title)
      expect(actual_titles).to match_array(expected_titles)
    end
  end

  describe "links between documents with different locales" do
    it "includes reverse links matching the specified locale" do
      target_edition = create(:edition)

      content_id_1 = SecureRandom.uuid
      _edition_1_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content_id 1, english, edition link, test link",
      )
      edition_1_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content_id 1, french, edition link, test link",
      )

      content_id_2 = SecureRandom.uuid
      _edition_2_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_2),
        title: "content_id 2, english, link set link, test link",
      )
      edition_2_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_2),
        title: "content_id 2, french, link set link, test link",
      )

      create(
        :link_set,
        content_id: content_id_2,
        links_hash: { "test_link" => [target_edition.content_id] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "fr",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expected_titles = [edition_1_fr, edition_2_fr].map(&:title)
        expect(actual_titles).to match_array(expected_titles)
      end
    end

    it "includes English language reverse links if there's no better match available" do
      target_edition = create(:edition)

      content_id_1 = SecureRandom.uuid
      edition_1_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content_id 1, english, edition link, test link",
      )
      _edition_1_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content_id 1, french, edition link, test link",
      )

      content_id_2 = SecureRandom.uuid
      edition_2_en = create(
        :edition,
        document: create(:document, locale: "en", content_id: content_id_2),
        title: "content_id 2, english, link set link, test link",
      )
      _edition_2_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_2),
        title: "content_id 2, french, link set link, test link",
      )

      create(
        :link_set,
        content_id: content_id_2,
        links_hash: { "test_link" => [target_edition.content_id] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "de",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expected_titles = [edition_1_en, edition_2_en].map(&:title)
        expect(actual_titles).to match_array(expected_titles)
      end
    end

    it "doesn't include a reverse link if none match the locale or English" do
      target_edition = create(:edition)

      content_id_1 = SecureRandom.uuid
      _edition_1_de = create(
        :edition,
        document: create(:document, locale: "de", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content id 1, german, edition link",
      )
      _edition_1_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_1),
        links_hash: { "test_link" => [target_edition.content_id] },
        title: "content id 1, french, edition link",
      )

      content_id_2 = SecureRandom.uuid
      _edition_2_de = create(
        :edition,
        document: create(:document, locale: "de", content_id: content_id_2),
        title: "content id 2, german, link set link",
      )
      _edition_2_fr = create(
        :edition,
        document: create(:document, locale: "fr", content_id: content_id_2),
        title: "content id 2, french, link set link",
      )

      create(
        :link_set,
        content_id: content_id_2,
        links_hash: { "test_link" => [target_edition.content_id] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "hu",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expect(actual_titles).to match_array([])
      end
    end

    context "when the Edition is live" do
      it "defaults to including a (live) 'en' reverse link if the locale-matching one is draft" do
        target_edition = create(:live_edition)

        content_id_1 = SecureRandom.uuid
        edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, english, edition link",
        )
        _edition_1_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, french, edition link",
        )

        content_id_2 = SecureRandom.uuid
        edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
          title: "content id 2, english, link set link",
        )
        _edition_2_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
          title: "content id 2, french, link set link",
        )

        create(
          :link_set,
          content_id: content_id_2,
          links_hash: { "test_link" => [target_edition.content_id] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "fr",
          ).request([target_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [edition_1_en, edition_2_en].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "doesn't include any reverse link if none are live" do
        target_edition = create(:live_edition)

        content_id_1 = SecureRandom.uuid
        _edition_1_en = create(
          :draft_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, english, edition link",
        )
        _edition_1_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, french, edition link",
        )

        content_id_2 = SecureRandom.uuid
        _edition_2_en = create(
          :draft_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
          title: "content id 2, english, link set link",
        )
        _edition_2_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
          title: "content id 2, french, link set link",
        )

        create(
          :link_set,
          content_id: content_id_2,
          links_hash: { "test_link" => [target_edition.content_id] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "fr",
          ).request([target_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = []
          expect(actual_titles).to match_array(expected_titles)
        end
      end
    end

    context "when the reverse linked Edition with matching locale is unpublished" do
      it "includes the reverse link if it's a permitted link_type" do
        target_edition = create(:live_edition)

        content_id_1 = SecureRandom.uuid
        _edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
          links_hash: { "related_statistical_data_sets" => [target_edition.content_id] },
          title: "content id 1, english, published, edition link, related_statistical_data_sets",
        )
        edition_1_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
          links_hash: { "related_statistical_data_sets" => [target_edition.content_id] },
          title: "content id 1, french, withdrawn, edition link, related_statistical_data_sets",
        )

        content_id_2 = SecureRandom.uuid
        _edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
          title: "content id 2, english, published, link set link, related_statistical_data_sets",
        )
        edition_2_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
          title: "content id 2, french, withdrawn, link set link, related_statistical_data_sets",
        )

        create(
          :link_set,
          content_id: content_id_2,
          links_hash: { "related_statistical_data_sets" => [target_edition.content_id] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "fr",
          ).request([target_edition, "related_statistical_data_sets"])

          actual_titles = request.load.map(&:title)
          expected_titles = [edition_1_fr, edition_2_fr].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "defaults to including a (not-unpublished) 'en' reverse link if the better-matching one isn't a permitted link_type" do
        target_edition = create(:live_edition)

        content_id_1 = SecureRandom.uuid
        edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, english, published, edition link, test link",
        )
        _edition_1_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
          links_hash: { "test_link" => [target_edition.content_id] },
          title: "content id 1, french, withdrawn, edition link, test link",
        )

        content_id_2 = SecureRandom.uuid
        edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
          title: "content id 2, english, published, link set link, test link",
        )
        _edition_2_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
          title: "content id 2, french, withdrawn, link set link, test link",
        )

        create(
          :link_set,
          content_id: content_id_2,
          links_hash: { "test_link" => [target_edition.content_id] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "fr",
          ).request([target_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [edition_1_en, edition_2_en].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end
    end
  end
end
