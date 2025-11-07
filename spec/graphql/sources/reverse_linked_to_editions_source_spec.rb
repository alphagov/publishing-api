RSpec.describe Sources::ReverseLinkedToEditionsSource do
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

  %i[link_set_links edition_links].each do |links_kind|
    context "when the link kind is #{links_kind}" do
      it "returns the specified reverse links" do
        target_edition = create(:edition)

        source_edition_1 = create(:edition,
                                  title: "edition 1, test link",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id },
                                  ])

        source_edition_2 = create(:edition,
                                  title: "edition 2, test link",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id },
                                  ])

        create(:edition,
               title: "edition 3, another link type",
               links_kind => [
                 { link_type: "another_link_type", target_content_id: target_edition.content_id },
               ])

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

        source_edition_0 = create(:edition,
                                  title: "edition 0, position 2",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id, position: 2 },
                                  ])
        source_edition_1 = create(:edition,
                                  title: "edition 1, position 1",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id, position: 1 },
                                  ])
        source_edition_2 = create(:edition,
                                  title: "edition 2, position 0",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id, position: 0 },
                                  ])

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "en",
          ).request([target_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [source_edition_2, source_edition_1, source_edition_0].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      context "when reverse links have the same `position`" do
        it "returns editions reverse-ordered by their associated reverse links' `id`" do
          target_edition = create(:edition)

          source_edition_1 = create(:edition,
                                    title: "edition 1, second link id",
                                    links_kind => [
                                      {
                                        link_type: "test_link",
                                        target_content_id: target_edition.content_id,
                                        position: 0,
                                        id: 10_002,
                                      },
                                    ])
          source_edition_0 = create(:edition,
                                    title: "edition 0, first link id",
                                    links_kind => [
                                      {
                                        link_type: "test_link",
                                        target_content_id: target_edition.content_id,
                                        position: 0,
                                        id: 10_001,
                                      },
                                    ])
          source_edition_2 = create(:edition,
                                    title: "edition 2, third link id",
                                    links_kind => [
                                      {
                                        link_type: "test_link",
                                        target_content_id: target_edition.content_id,
                                        position: 0,
                                        id: 10_003,
                                      },
                                    ])

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

      context "when the linked item is unpublished" do
        it "includes unpublished links when they are of a permitted type" do
          target_edition = create(:edition, content_store: "live")

          unpublished_edition = create(:withdrawn_unpublished_edition,
                                       content_store: "live",
                                       title: "edition 2, withdrawn, parent link",
                                       links_kind => [
                                         { link_type: "parent", target_content_id: target_edition.content_id },
                                       ])

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: target_edition.content_store,
              locale: "en",
            ).request([target_edition, "parent"])

            actual_titles = request.load.map(&:title)
            expected_titles = [unpublished_edition].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "does not include unpublished links when they are of another type" do
          target_edition = create(:edition, content_store: "live")

          create(:withdrawn_unpublished_edition,
                 content_store: "live",
                 title: "edition 0, withdrawn, test_link link",
                 links_kind => [
                   { link_type: "test_link", target_content_id: target_edition.content_id },
                 ])

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
          title: "renderable edition 1",
          links_kind => [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )
        create(
          :redirect_edition,
          title: "non-renderable edition (redirect)",
          links_kind => [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )

        GraphQL::Dataloader.with_dataloading do |dataloader|
          request = dataloader.with(
            described_class,
            content_store: target_edition.content_store,
            locale: "en",
          ).request([target_edition, "test_link"])

          actual_titles = request.load.map(&:title)
          expected_titles = [renderable_edition_1].map(&:title)
          expect(actual_titles).to match_array(expected_titles)
        end
      end

      describe "links between documents with different locales" do
        it "includes reverse links matching the specified locale" do
          target_edition = create(:edition)

          source_content_id = SecureRandom.uuid
          create(
            :edition,
            title: "english, test link",
            document: create(:document, locale: "en", content_id: source_content_id),
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          french_edition = create(
            :edition,
            title: "french, test link",
            document: create(:document, locale: "fr", content_id: source_content_id),
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: target_edition.content_store,
              locale: "fr",
            ).request([target_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [french_edition].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "includes English language reverse links if there's no better match available" do
          target_edition = create(:edition)

          source_content_id = SecureRandom.uuid
          english_edition = create(
            :edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english, test link",
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french, test link",
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )

          GraphQL::Dataloader.with_dataloading do |dataloader|
            request = dataloader.with(
              described_class,
              content_store: target_edition.content_store,
              locale: "de",
            ).request([target_edition, "test_link"])

            actual_titles = request.load.map(&:title)
            expected_titles = [english_edition].map(&:title)
            expect(actual_titles).to match_array(expected_titles)
          end
        end

        it "doesn't include a reverse link if none match the locale or English" do
          target_edition = create(:edition)

          source_content_id = SecureRandom.uuid
          create(
            :edition,
            document: create(:document, locale: "de", content_id: source_content_id),
            title: "german",
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french",
            links_kind => [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
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

            source_content_id = SecureRandom.uuid
            english_edition = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: source_content_id),
              title: "english",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: source_content_id),
              title: "french",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "fr",
              ).request([target_edition, "test_link"])

              actual_titles = request.load.map(&:title)
              expected_titles = [english_edition].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "doesn't include any reverse link if none are live" do
            target_edition = create(:live_edition)

            source_content_id = SecureRandom.uuid
            create(
              :draft_edition,
              document: create(:document, locale: "en", content_id: source_content_id),
              title: "english",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
            )
            create(
              :draft_edition,
              document: create(:document, locale: "fr", content_id: source_content_id),
              title: "french",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
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

            source_content_id = SecureRandom.uuid
            create(
              :live_edition,
              document: create(:document, locale: "en", content_id: source_content_id),
              title: "english, published, related_statistical_data_sets",
              links_kind => [
                { link_type: "related_statistical_data_sets", target_content_id: target_edition.content_id },
              ],
            )
            french_edition = create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: source_content_id),
              title: "french, withdrawn, related_statistical_data_sets",
              links_kind => [
                { link_type: "related_statistical_data_sets", target_content_id: target_edition.content_id },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "fr",
              ).request([target_edition, "related_statistical_data_sets"])

              actual_titles = request.load.map(&:title)
              expected_titles = [french_edition].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end

          it "defaults to including a (not-unpublished) 'en' reverse link if the better-matching one isn't a permitted link_type" do
            target_edition = create(:live_edition)

            source_content_id = SecureRandom.uuid
            english_edition = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: source_content_id),
              title: "english, published, test link",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
            )
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: source_content_id),
              title: "french, withdrawn, test link",
              links_kind => [
                { link_type: "test_link", target_content_id: target_edition.content_id },
              ],
            )

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "fr",
              ).request([target_edition, "test_link"])

              actual_titles = request.load.map(&:title)
              expected_titles = [english_edition].map(&:title)
              expect(actual_titles).to match_array(expected_titles)
            end
          end
        end
      end
    end
  end
end
