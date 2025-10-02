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
      ).request([source_edition, "test_link"])

      expect(request.load).to eq([target_edition_0, target_edition_1, target_edition_2, target_edition_3])
    end
  end

  context "when links have the same `position`" do
    it "returns editions reverse-ordered by their associated links' `id`" do
      position = 0

      third_link_target_edition = create(:edition)
      first_link_target_edition = create(:edition)
      second_link_target_edition = create(:edition)
      fourth_link_target_edition = create(:edition)

      source_edition = create(:edition, content_store: "draft")
      create(:link, edition: source_edition, target_content_id: first_link_target_edition.content_id, position:, link_type: "test_link")
      create(:link, edition: source_edition, target_content_id: second_link_target_edition.content_id, position:, link_type: "test_link")

      link_set = create(:link_set, content_id: source_edition.content_id)
      create(:link, link_set:, target_content_id: third_link_target_edition.content_id, position:, link_type: "test_link")
      create(:link, link_set:, target_content_id: fourth_link_target_edition.content_id, position:, link_type: "test_link")

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "en",
        ).request([source_edition, "test_link"])

        expect(request.load).to eq([
          fourth_link_target_edition,
          third_link_target_edition,
          second_link_target_edition,
          first_link_target_edition,
        ])
      end
    end
  end

  context "when the same document is both a link set link and an edition link" do
    it "only returns the document once" do
      source_edition = create(:live_edition)
      target_edition = create(:live_edition)

      create(
        :link,
        edition: source_edition,
        target_content_id: target_edition.content_id,
        link_type: "test_link",
      )

      create(
        :link,
        link_set: create(:link_set, content_id: source_edition.content_id),
        target_content_id: target_edition.content_id,
        link_type: "test_link",
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "en",
        ).request([source_edition, "test_link"])

        expect(request.load).to eq([target_edition])
      end
    end
  end

  context "when the linked item is unpublished" do
    # we're including children as a direct link type here, but children is a
    # reverse link type
    Link::PERMITTED_UNPUBLISHED_LINK_TYPES.each do |link_type|
      it "includes unpublished withdrawn links when they are of the permitted link type #{link_type}" do
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

      it "excludes unpublished non-withdrawn links even when they are of the permitted link type #{link_type}" do
        edition_linked_edition = create(:edition, content_store: "live")
        redirect_edition_linked_edition = create(:redirect_unpublished_edition, content_store: "live")
        link_set_linked_edition = create(:edition, content_store: "live")
        redirect_link_set_linked_edition = create(:redirect_unpublished_edition, content_store: "live")

        source_edition = create(:edition,
                                content_store: "live",
                                links_hash: {
                                  link_type => [edition_linked_edition.content_id, redirect_edition_linked_edition.content_id],
                                })

        link_set = create(:link_set, content_id: source_edition.content_id)
        create(:link, link_set:, target_content_id: link_set_linked_edition.content_id, link_type:)
        create(:link, link_set:, target_content_id: redirect_link_set_linked_edition.content_id, link_type:)

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "en",
          ).request([source_edition, link_type])

          expect(request.load).to match_array([edition_linked_edition, link_set_linked_edition])
        end
      end
    end

    it "does not include unpublished links when they are of another link type" do
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
    it "includes links matching the specified locale" do
      content_id_1 = SecureRandom.uuid
      _edition_1_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_1))
      edition_1_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1))

      content_id_2 = SecureRandom.uuid
      _edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      source_edition = create(
        :edition,
        links_hash: { "test_link" => [content_id_1] },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: { "test_link" => [content_id_2] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "fr",
        ).request([source_edition, "test_link"])

        expect(request.load).to contain_exactly(edition_1_fr, edition_2_fr)
      end
    end

    it "includes English language links if there's no better match available" do
      content_id_1 = SecureRandom.uuid
      edition_1_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_1))
      _edition_1_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1))

      content_id_2 = SecureRandom.uuid
      edition_2_en = create(:edition, document: create(:document, locale: "en", content_id: content_id_2))
      _edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      source_edition = create(
        :edition,
        links_hash: { "test_link" => [content_id_1] },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: { "test_link" => [content_id_2] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "de",
        ).request([source_edition, "test_link"])

        expect(request.load).to contain_exactly(edition_1_en, edition_2_en)
      end
    end

    it "doesn't include a link if none match the locale or English" do
      content_id_1 = SecureRandom.uuid
      _edition_1_de = create(:edition, document: create(:document, locale: "de", content_id: content_id_1))
      _edition_1_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1))

      content_id_2 = SecureRandom.uuid
      _edition_2_de = create(:edition, document: create(:document, locale: "de", content_id: content_id_2))
      _edition_2_fr = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2))

      source_edition = create(
        :edition,
        links_hash: { "test_link" => [content_id_1] },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: { "test_link" => [content_id_2] },
      )

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: "hu",
        ).request([source_edition, "test_link"])

        expect(request.load).to match_array([])
      end
    end

    context "when the source Edition is live" do
      it "defaults to including a (live) 'en' link if the locale-matching one is draft" do
        content_id_1 = SecureRandom.uuid
        edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
        )
        _edition_1_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
        )

        content_id_2 = SecureRandom.uuid
        edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
        )
        _edition_2_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
        )

        source_edition = create(
          :live_edition,
          links_hash: { "test_link" => [content_id_1] },
        )

        create(
          :link_set,
          content_id: source_edition.content_id,
          links_hash: { "test_link" => [content_id_2] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "fr",
          ).request([source_edition, "test_link"])

          expect(request.load).to contain_exactly(edition_1_en, edition_2_en)
        end
      end

      it "doesn't include any link if none are live" do
        content_id_1 = SecureRandom.uuid
        _edition_1_en = create(
          :draft_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
        )
        _edition_1_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
        )

        content_id_2 = SecureRandom.uuid
        _edition_2_en = create(
          :draft_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
        )
        _edition_2_fr = create(
          :draft_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
        )

        source_edition = create(
          :live_edition,
          links_hash: { "test_link" => [content_id_1] },
        )

        create(
          :link_set,
          content_id: source_edition.content_id,
          links_hash: { "test_link" => [content_id_2] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "fr",
          ).request([source_edition, "test_link"])

          expect(request.load).to match_array([])
        end
      end
    end

    context "when the linked Edition with matching locale is unpublished" do
      it "includes the link if it's a permitted link_type" do
        content_id_1 = SecureRandom.uuid
        _edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
        )
        edition_1_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
        )

        content_id_2 = SecureRandom.uuid
        _edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
        )
        edition_2_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
        )

        source_edition = create(
          :live_edition,
          links_hash: { "related_statistical_data_sets" => [content_id_1] },
        )

        create(
          :link_set,
          content_id: source_edition.content_id,
          links_hash: { "related_statistical_data_sets" => [content_id_2] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "fr",
          ).request([source_edition, "related_statistical_data_sets"])

          expect(request.load).to contain_exactly(edition_1_fr, edition_2_fr)
        end
      end

      it "defaults to including a (not-unpublished) 'en' link if the better-matching one isn't a permitted link_type" do
        content_id_1 = SecureRandom.uuid
        edition_1_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_1),
        )
        _edition_1_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_1),
        )

        content_id_2 = SecureRandom.uuid
        edition_2_en = create(
          :live_edition,
          document: create(:document, locale: "en", content_id: content_id_2),
        )
        _edition_2_fr = create(
          :withdrawn_unpublished_edition,
          document: create(:document, locale: "fr", content_id: content_id_2),
        )

        source_edition = create(
          :live_edition,
          links_hash: { "test_link" => [content_id_1] },
        )

        create(
          :link_set,
          content_id: source_edition.content_id,
          links_hash: { "test_link" => [content_id_2] },
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "fr",
          ).request([source_edition, "test_link"])

          expect(request.load).to contain_exactly(edition_1_en, edition_2_en)
        end
      end
    end
  end

  it "doesn't include non-renderable links" do
    renderable_edition_1 = create(:edition)
    renderable_edition_2 = create(:edition)

    source_edition = create(
      :edition,
      links_hash: {
        "test_link" => [renderable_edition_1.content_id, create(:redirect_edition).content_id],
      },
    )

    link_set = create(:link_set, content_id: source_edition.content_id)
    create(:link, link_set:, target_content_id: renderable_edition_2.content_id, link_type: "test_link")
    create(:link, link_set:, target_content_id: create(:gone_edition).content_id, link_type: "test_link")

    GraphQL::Dataloader.with_dataloading do |dataloader|
      request = dataloader.with(
        described_class,
        content_store: source_edition.content_store,
        locale: "en",
      ).request([source_edition, "test_link"])

      expect(request.load).to match_array([renderable_edition_1, renderable_edition_2])
    end
  end
end
