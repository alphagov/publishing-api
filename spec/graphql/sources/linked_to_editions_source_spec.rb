RSpec.describe Sources::LinkedToEditionsSource do
  context "when there is a mix of link set links and edition links" do
    it "returns a mixture of links" do
      target_edition_1 = create(:edition, title: "edition 1, test link, edition link")
      target_edition_2 = create(:edition, title: "edition 2, another link type, edition link")
      target_edition_3 = create(:edition, title: "edition 3, test link, link set link")

      source_edition = create(:edition,
                              edition_links: [
                                { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                { link_type: "another_link_type", target_content_id: target_edition_2.content_id },
                              ],
                              link_set_links: [
                                { link_type: "test_link", target_content_id: target_edition_3.content_id },
                              ])

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

    context "when the same document is both a link set link and an edition link" do
      it "only returns the document once" do
        target_edition = create(:live_edition)
        source_edition = create(:live_edition,
                                edition_links: [
                                  { link_type: "test_link", target_content_id: target_edition.content_id },
                                ],
                                link_set_links: [
                                  { link_type: "test_link", target_content_id: target_edition.content_id },
                                ])

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
  end

  %i[link_set_links edition_links].each do |links_kind|
    context "when the link kind is #{links_kind}" do
      it "returns the specified links" do
        target_edition_1 = create(:edition, title: "edition 1, test link")
        target_edition_2 = create(:edition, title: "edition 2, another link type")
        target_edition_3 = create(:edition, title: "edition 3, test link")

        source_edition = create(:edition,
                                links_kind => [
                                  { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                  { link_type: "another_link_type", target_content_id: target_edition_2.content_id },
                                  { link_type: "test_link", target_content_id: target_edition_3.content_id },
                                ])

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
        target_edition_0 = create(:edition, content_store: "live", title: "edition 0, live")
        target_edition_1 = create(:edition, content_store: "draft", title: "edition 1, draft")

        source_edition = create(:edition,
                                content_store: "draft",
                                links_kind => [
                                  { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                  { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                ])

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "en",
          ).request([source_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_1.title]
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      it "returns editions in order of their associated link's `position`" do
        target_edition_0 = create(:edition, title: "edition 0")
        target_edition_1 = create(:edition, title: "edition 1")

        source_edition = create(:edition,
                                content_store: "draft",
                                links_kind => [
                                  { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                  { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                ])

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "en",
          ).request([source_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [target_edition_0, target_edition_1].map(&:title)
          expect(actual_titles).to eq(expected_titles)
        end
      end

      context "when links have the same `position`" do
        it "returns editions reverse-ordered by their associated links' `id`" do
          target_edition_0 = create(:edition, title: "edition 0, third link id")
          target_edition_1 = create(:edition, title: "edition 1, first link id")
          target_edition_2 = create(:edition, title: "edition 2, second link id")
          target_edition_3 = create(:edition, title: "edition 3, fourth link id")

          source_edition = create(:edition,
                                  content_store: "draft",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition_1.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_2.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_0.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_3.content_id, position: 0 },
                                  ])

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

      context "when the linked item is unpublished" do
        it "includes unpublished links when they are of a permitted type" do
          target_edition_0 = create(:edition, content_store: "live", title: "edition 0, published")
          target_edition_1 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 1, withdrawn")

          source_edition = create(:edition,
                                  content_store: "live",
                                  links_kind => [
                                    { link_type: "parent", target_content_id: target_edition_0.content_id },
                                    { link_type: "parent", target_content_id: target_edition_1.content_id },
                                  ])

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "en",
            ).request([source_edition, "parent"])

            actual_titles = request.load.map(&:title)
            expected_titles = [target_edition_0, target_edition_1].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "does not include unpublished links when they are of another type" do
          target_edition_0 = create(:edition, content_store: "live", title: "edition 0, published")
          target_edition_1 = create(:withdrawn_unpublished_edition, content_store: "live", title: "edition 1, withdrawn")

          source_edition = create(:edition,
                                  content_store: "live",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                    { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                  ])

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "en",
            ).request([source_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [target_edition_0.title]
            expect(actual_titles).to match_array(expected_titles)
          end
        end
      end

      describe "links between documents with different locales" do
        it "includes links matching the specified locale (french)" do
          target_content_id = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "en", content_id: target_content_id), title: "english")
          french_edition = create(:edition, document: create(:document, locale: "fr", content_id: target_content_id), title: "french")

          source_edition = create(
            :edition,
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
          )

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "fr",
            ).request([source_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [french_edition.title]
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "includes English language links if there's no better match available" do
          target_content_id = SecureRandom.uuid
          english_edition = create(:edition, document: create(:document, locale: "en", content_id: target_content_id), title: "english edition")
          create(:edition, document: create(:document, locale: "fr", content_id: target_content_id), title: "french edition")

          source_edition = create(
            :edition,
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
          )

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: source_edition.content_store,
              locale: "de",
            ).request([source_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [english_edition.title]
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "doesn't include a link if none match the locale or English" do
          target_content_id = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "de", content_id: target_content_id), title: "german")
          create(:edition, document: create(:document, locale: "fr", content_id: target_content_id), title: "french")

          source_edition = create(
            :edition,
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
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
            target_content_id = SecureRandom.uuid
            english_edition = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english live edition",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french draft edition",
            )

            source_edition = create(
              :live_edition,
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: source_edition.content_store,
                locale: "fr",
              ).request([source_edition, "test_link"])

              actual_titles = request.load.map(&:title)
              expected_titles = [english_edition.title]
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "doesn't include any links if none of the target editions are live" do
            target_content_id = SecureRandom.uuid
            create(
              :draft_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english draft edition",
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french draft edition",
            )

            source_edition = create(
              :live_edition,
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
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
            target_content_id = SecureRandom.uuid
            create(
              :live_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english, published, related_statistical_data_sets",
            )
            french_withdrawn_edition = create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french, withdrawn, related_statistical_data_sets",
            )

            source_edition = create(
              :live_edition,
              links_kind => [
                { link_type: "related_statistical_data_sets", target_content_id: },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: source_edition.content_store,
                locale: "fr",
              ).request([source_edition, "related_statistical_data_sets"])

              actual_titles = request.load.map(&:title)
              expected_titles = [french_withdrawn_edition.title]
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "falls back to an english document if the unpublished locale-matching one isn't a permitted unpublished link_type" do
            target_content_id = SecureRandom.uuid
            english_edition = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english, published, test_link",
            )
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french, withdrawn, test_link",
            )

            source_edition = create(
              :live_edition,
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: source_edition.content_store,
                locale: "fr",
              ).request([source_edition, "test_link"])

              actual_titles = request.load.map(&:title)
              expected_titles = [english_edition.title]
              expect(actual_titles).to match_array(expected_titles)
            end
          end
        end
      end

      it "doesn't include non-renderable links" do
        renderable_edition_1 = create(:edition, title: "renderable edition 1")
        non_renderable_edition = create(:redirect_edition, title: "non-renderable edition (redirect)")

        source_edition = create(
          :edition,
          links_kind => [
            { link_type: "test_link", target_content_id: renderable_edition_1.content_id },
            { link_type: "test_link", target_content_id: non_renderable_edition.content_id },
          ],
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: source_edition.content_store,
            locale: "en",
          ).request([source_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [renderable_edition_1.title]
          expect(actual_titles).to match_array(expected_titles)
        end
      end
    end
  end
end
