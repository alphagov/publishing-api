RSpec.describe Sources::LinkedToEditionsSource do
  context "temporary context to indent code" do
    it "returns a mixture of links when both present" do
      target_edition_1 = create(:edition, title: "edition 1, test link, edition link")
      target_edition_2 = create(:edition, title: "edition 2, another link type, edition link")
      target_edition_3 = create(:edition, title: "edition 3, test link, link set link")

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

        actual_titles = request.load.map(&:title)
        expected_titles = [target_edition_1, target_edition_3].map(&:title)
        expect(actual_titles).to match_array(expected_titles)
      end
    end
  end

  ["temporary loop to indent code"].each do
    context "temporary context to indent code" do
      it "returns the specified link set links" do
        source_edition = create(:edition)
        target_edition_1 = create(:edition, title: "edition 1, test link")
        target_edition_2 = create(:edition, title: "edition 2, another link type")
        target_edition_3 = create(:edition, title: "edition 3, test link")
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

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_1, target_edition_3].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "returns the specified edition links" do
        target_edition_1 = create(:edition, title: "edition 1, test link")
        target_edition_2 = create(:edition, title: "edition 2, another link type")
        target_edition_3 = create(:edition, title: "edition 3, test link")

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

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_1, target_edition_3].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "returns links from only the requested content store" do
        target_edition_1 = create(:edition, content_store: "live", title: "edition 1, live, edition link")
        target_edition_2 = create(:edition, content_store: "live", title: "edition 2, live, link set link")
        target_edition_3 = create(:edition, content_store: "draft", title: "edition 3, draft, edition link")
        target_edition_4 = create(:edition, content_store: "draft", title: "edition 4, draft, link set link")

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

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_3, target_edition_4].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "returns editions in order of their associated link's `position`" do
        target_edition_0 = create(:edition, title: "edition 0, link set link")
        target_edition_1 = create(:edition, title: "edition 1, edition link")
        target_edition_2 = create(:edition, title: "edition 2, link set link")
        target_edition_3 = create(:edition, title: "edition 3, edition link")

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

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_0, target_edition_1, target_edition_2, target_edition_3].map(&:title)
          expect(actual_titles).to eq(expected_titles)
        end
      end

      context "when links have the same `position`" do
        it "returns editions reverse-ordered by their associated links' `id`" do
          position = 0

          target_edition_0 = create(:edition, title: "edition 0, link set link, third link id")
          target_edition_1 = create(:edition, title: "edition 1, edition link, first link id")
          target_edition_2 = create(:edition, title: "edition 2, link set link, second link id")
          target_edition_3 = create(:edition, title: "edition 3, edition link, fourth link id")

          source_edition = create(:edition, content_store: "draft")
          create(:link, edition: source_edition, target_content_id: target_edition_1.content_id, position:, link_type: "test_link")
          create(:link, edition: source_edition, target_content_id: target_edition_2.content_id, position:, link_type: "test_link")

          link_set = create(:link_set, content_id: source_edition.content_id)
          create(:link, link_set:, target_content_id: target_edition_0.content_id, position:, link_type: "test_link")
          create(:link, link_set:, target_content_id: target_edition_3.content_id, position:, link_type: "test_link")

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "en",
            ).request([source_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [target_edition_3, target_edition_0, target_edition_2, target_edition_1].map(&:title)
            expect(actual_titles).to eq(expected_titles)
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
        it "includes unpublished links when they are of a permitted type" do
          target_edition_0 = create(:edition, content_store: "live", title: "edition 0, edition link, published")
          target_edition_1 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 1, edition link, withdrawn")
          target_edition_2 = create(:edition, content_store: "live", title: "edition 2, link set link, published")
          target_edition_3 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 3, link set link, withdrawn")

          source_edition = create(:edition,
                                  content_store: "live",
                                  links_hash: {
                                    "parent" => [target_edition_0.content_id, target_edition_1.content_id],
                                  })

          link_set = create(:link_set, content_id: source_edition.content_id)
          create(:link, link_set:, target_content_id: target_edition_2.content_id, link_type: "parent")
          create(:link, link_set:, target_content_id: target_edition_3.content_id, link_type: "parent")

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "en",
            ).request([source_edition, "parent"])

            actual_titles = request.load.map(&:title)
            expected_titles = [target_edition_0, target_edition_1, target_edition_2, target_edition_3].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "does not include unpublished links when they are of another type" do
          target_edition_0 = create(:edition, content_store: "live", title: "edition 0, edition link, published")
          target_edition_1 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 1, edition link, withdrawn")
          target_edition_2 = create(:edition, content_store: "live", title: "edition 2, link set link, published")
          target_edition_3 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 3, link set link, withdrawn")

          source_edition = create(:edition,
                                  content_store: "live",
                                  links_hash: {
                                    "test_link" => [target_edition_0.content_id, target_edition_1.content_id],
                                  })

          link_set = create(:link_set, content_id: source_edition.content_id)
          create(:link, link_set:, target_content_id: target_edition_2.content_id, link_type: "test_link")
          create(:link, link_set:, target_content_id: target_edition_3.content_id, link_type: "test_link")

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "en",
            ).request([source_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [target_edition_0, target_edition_2].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end
      end

      describe "links between documents with different locales" do
        it "includes links matching the specified locale" do
          content_id_1 = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "en", content_id: content_id_1), title: "content id 1, english, edition link")
          fr_edition_1 = create(:edition, document: create(:document, locale: "fr", content_id: content_id_1), title: "content id 1, french, edition link")

          content_id_2 = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "en", content_id: content_id_2), title: "content id 2, english, link set link")
          fr_edition_2 = create(:edition, document: create(:document, locale: "fr", content_id: content_id_2), title: "content id 2, french, link set link")

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

            actual_titles = request.load.map(&:title)
            expected_titles = [fr_edition_1, fr_edition_2].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "includes English language links if there's no better match available" do
          content_id_1 = SecureRandom.uuid
          en_edition_1 = create(:edition, document: create(:document, locale: "en", content_id: content_id_1), title: "content id 1, english, edition link")
          create(:edition, document: create(:document, locale: "fr", content_id: content_id_1), title: "content id 1, french, edition link")

          content_id_2 = SecureRandom.uuid
          en_edition_2 = create(:edition, document: create(:document, locale: "en", content_id: content_id_2), title: "content id 2, english, link set link")
          create(:edition, document: create(:document, locale: "fr", content_id: content_id_2), title: "content id 2, french, link set link")

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

            actual_titles = request.load.map(&:title)
            expected_titles = [en_edition_1, en_edition_2].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "doesn't include a link if none match the locale or English" do
          content_id_1 = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "de", content_id: content_id_1), title: "content id 1, german, edition link")
          create(:edition, document: create(:document, locale: "fr", content_id: content_id_1), title: "content id 1, french, edition link")

          content_id_2 = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "de", content_id: content_id_2), title: "content id 2, german, link set link")
          create(:edition, document: create(:document, locale: "fr", content_id: content_id_2), title: "content id 2, french, link set link")

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

            actual_titles = request.load.map(&:title)
            expected_titles = []
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        context "when the source Edition is live" do
          it "defaults to including a (live) 'en' link if the locale-matching one is draft" do
            content_id_1 = SecureRandom.uuid
            en_edition_1 = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_1),
              title: "content id 1, english, live, edition link",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: content_id_1),
              title: "content id 1, french, draft, edition link",
            )

            content_id_2 = SecureRandom.uuid
            en_edition_2 = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_2),
              title: "content id 2, english, live, link set link",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: content_id_2),
              title: "content id 2, french, draft, link set link",
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

              actual_titles = request.load.map(&:title)
              expected_titles = [en_edition_1, en_edition_2].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "doesn't include any link if none are live" do
            content_id_1 = SecureRandom.uuid
            create(
              :draft_edition,
              document: create(:document, locale: "en", content_id: content_id_1),
              title: "content id 1, english, draft, edition link",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: content_id_1),
              title: "content id 1, french, draft, edition link",
            )

            content_id_2 = SecureRandom.uuid
            create(
              :draft_edition,
              document: create(:document, locale: "en", content_id: content_id_2),
              title: "content id 2, english, draft, link set link",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: content_id_2),
              title: "content id 2, french, draft, link set link",
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

              actual_titles = request.load.map(&:title)
              expected_titles = []
              expect(actual_titles).to match_array(expected_titles)
            end
          end
        end

        context "when the linked Edition with matching locale is unpublished" do
          it "includes the link if it's a permitted link_type" do
            content_id_1 = SecureRandom.uuid
            create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_1),
              title: "content id 1, english, published, edition link, related_statistical_data_sets",
            )
            fr_edition_1 = create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: content_id_1),
              title: "content id 1, french, withdrawn, edition link, related_statistical_data_sets",
            )

            content_id_2 = SecureRandom.uuid
            create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_2),
              title: "content id 2, english, published, link set link, related_statistical_data_sets",
            )
            fr_edition_2 = create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: content_id_2),
              title: "content id 2, french, withdrawn, link set link, related_statistical_data_sets",
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

              actual_titles = request.load.map(&:title)
              expected_titles = [fr_edition_1, fr_edition_2].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "defaults to including a (not-unpublished) 'en' link if the better-matching one isn't a permitted link_type" do
            content_id_1 = SecureRandom.uuid
            en_edition_1 = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_1),
              title: "content id 1, english, published, edition link, test_link",
            )
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: content_id_1),
              title: "content id 1, french, withdrawn, edition link, test_link",
            )

            content_id_2 = SecureRandom.uuid
            en_edition_2 = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: content_id_2),
              title: "content id 2, english, published, link set link, test_link",
            )
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: content_id_2),
              title: "content id 2, french, withdrawn, link set link, test_link",
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

              actual_titles = request.load.map(&:title)
              expected_titles = [en_edition_1, en_edition_2].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end
        end
      end

      it "doesn't include non-renderable links" do
        renderable_edition_1 = create(:edition, title: "renderable edition 1")
        renderable_edition_2 = create(:edition, title: "renderable edition 2")
        non_renderable_edition = create(:redirect_edition, title: "non-renderable edition (redirect)")

        source_edition = create(
          :edition,
          links_hash: {
            "test_link" => [renderable_edition_1.content_id, non_renderable_edition.content_id],
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

          actual_titles = request.load.map(&:title)
          expected_titles = [renderable_edition_1, renderable_edition_2].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end
    end
  end
end
