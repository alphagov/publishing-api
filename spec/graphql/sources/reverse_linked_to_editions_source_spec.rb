RSpec.describe Sources::ReverseLinkedToEditionsSource do
  context "when the same target content has a mix of link set links and edition links for the same link type" do
    it "returns only the edition links" do
      target_edition = create(:edition)

      source_edition_1 = create(:edition,
                                title: "edition 1, edition link",
                                edition_links: [
                                  {
                                    link_type: "test_link",
                                    target_content_id: target_edition.content_id,
                                  },
                                ])
      create(:edition,
             title: "edition 2, link set link",
             link_set_links: [
               {
                 link_type: "test_link",
                 target_content_id: target_edition.content_id,
               },
             ])

      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: target_edition.content_store,
          locale: "en",
        ).request([target_edition, "test_link"])

        actual_titles = request.load.map(&:title)
        expected_titles = [source_edition_1].map(&:title)
        expect(actual_titles).to match_array(expected_titles)
      end
    end
  end

  context "when the same document is both a link set link and an edition link" do
    it "only returns the document once" do
      target_edition = create(:edition)

      source_edition = create(:edition,
                              edition_links: [
                                { link_type: "test_link", target_content_id: target_edition.content_id },
                              ],
                              link_set_links: [
                                { link_type: "test_link", target_content_id: target_edition.content_id },
                              ])

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
                                  title: "edition 0, position 1",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id, position: 1 },
                                  ])
        source_edition_1 = create(:edition,
                                  title: "edition 1, position 2",
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition.content_id, position: 2 },
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
          expected_titles = [source_edition_2, source_edition_0, source_edition_1].map(&:title)
          expect(actual_titles).to eq(expected_titles)
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

      context "when the reverse linked item is unpublished" do
        context "when the reverse links are of a permitted unpublished link type" do
          it "includes unpublished reverse links when the unpublishing type is withdrawal" do
            target_edition = create(:live_edition)

            source_edition = create(:withdrawn_unpublished_edition,
                                    title: "withdrawn edition",
                                    links_kind => [{
                                      link_type: "parent",
                                      target_content_id: target_edition.content_id,
                                    }])

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "en",
              ).request([target_edition, "parent"])

              actual_titles = request.load.map(&:title)
              expected_titles = [source_edition].map(&:title)
              expect(actual_titles).to eq(expected_titles)
            end
          end

          it "does not include unpublished reverse links when the unpublishing type is not withdrawal" do
            target_edition = create(:live_edition)

            create(:gone_unpublished_edition,
                   title: "gone edition",
                   links_kind => [{
                     link_type: "parent",
                     target_content_id: target_edition.content_id,
                   }])
            create(:redirect_unpublished_edition,
                   title: "redirect edition",
                   links_kind => [{
                     link_type: "parent",
                     target_content_id: target_edition.content_id,
                   }])
            create(:substitute_unpublished_edition,
                   title: "substitute edition",
                   links_kind => [{
                     link_type: "parent",
                     target_content_id: target_edition.content_id,
                   }])
            create(:vanish_unpublished_edition,
                   title: "vanish edition",
                   links_kind => [{
                     link_type: "parent",
                     target_content_id: target_edition.content_id,
                   }])

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "en",
              ).request([target_edition, "parent"])

              actual_titles = request.load.map(&:title)
              expected_titles = []
              expect(actual_titles).to eq(expected_titles)
            end
          end
        end

        context "when the reverse links aren't of a permitted unpublished link type" do
          it "does not include unpublished reverse links even if the unpublishing type is withdrawal" do
            target_edition = create(:live_edition)

            create(:withdrawn_unpublished_edition,
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

          it "also does not include unpublished reverse links when the unpublishing type is not withdrawal" do
            target_edition = create(:live_edition)

            create(:gone_unpublished_edition,
                   title: "gone edition",
                   links_kind => [{
                     link_type: "test_link",
                     target_content_id: target_edition.content_id,
                   }])
            create(:redirect_unpublished_edition,
                   title: "redirect edition",
                   links_kind => [{
                     link_type: "test_link",
                     target_content_id: target_edition.content_id,
                   }])
            create(:substitute_unpublished_edition,
                   title: "substitute edition",
                   links_kind => [{
                     link_type: "test_link",
                     target_content_id: target_edition.content_id,
                   }])
            create(:vanish_unpublished_edition,
                   title: "vanish edition",
                   links_kind => [{
                     link_type: "test_link",
                     target_content_id: target_edition.content_id,
                   }])

            GraphQL::Dataloader.with_dataloading do |dataloader|
              request = dataloader.with(
                described_class,
                content_store: target_edition.content_store,
                locale: "en",
              ).request([target_edition, "test_link"])

              actual_titles = request.load.map(&:title)
              expected_titles = []
              expect(actual_titles).to eq(expected_titles)
            end
          end
        end
      end

      it "doesn't include linked editions of non-renderable document types" do
        target_edition = create(:edition)

        renderable_edition = create(
          :edition,
          title: "renderable edition",
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
          expected_titles = [renderable_edition].map(&:title)
          expect(actual_titles).to eq(expected_titles)
        end
      end
    end
  end

  describe "links between documents with different locales" do
    %i[link_set_links edition_links].each do |links_kind|
      context "when the link kind is #{links_kind}" do
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
            expect(actual_titles).to eq(expected_titles)
          end
        end
      end
    end

    context "when the link kind is link_set_links" do
      it "includes English language reverse links if there's no better match available" do
        target_edition = create(:edition)

        source_content_id = SecureRandom.uuid
        english_edition = create(
          :edition,
          document: create(:document, locale: "en", content_id: source_content_id),
          title: "english, test link",
          link_set_links: [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )
        create(
          :edition,
          document: create(:document, locale: "fr", content_id: source_content_id),
          title: "french, test link",
          link_set_links: [
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
          expect(actual_titles).to eq(expected_titles)
        end
      end

      it "doesn't include a reverse link if none match the locale or English" do
        target_edition = create(:edition)

        source_content_id = SecureRandom.uuid
        create(
          :edition,
          document: create(:document, locale: "de", content_id: source_content_id),
          title: "german",
          link_set_links: [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )
        create(
          :edition,
          document: create(:document, locale: "fr", content_id: source_content_id),
          title: "french",
          link_set_links: [
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
          expect(actual_titles).to eq([])
        end
      end
    end

    context "when the link kind is edition_links" do
      it "doesn't include a reverse link if none match the locale" do
        target_edition = create(:edition)

        source_content_id = SecureRandom.uuid
        create(
          :edition,
          document: create(:document, locale: "en", content_id: source_content_id),
          title: "english, test link",
          edition_links: [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )
        create(
          :edition,
          document: create(:document, locale: "de", content_id: source_content_id),
          title: "german",
          edition_links: [
            { link_type: "test_link", target_content_id: target_edition.content_id },
          ],
        )
        create(
          :edition,
          document: create(:document, locale: "fr", content_id: source_content_id),
          title: "french",
          edition_links: [
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
          expect(actual_titles).to eq([])
        end
      end
    end

    context "when the Edition is live" do
      context "when the link kind is link_set_links" do
        it "defaults to including a (live) 'en' reverse link when the locale-matching one is draft" do
          target_edition = create(:live_edition)

          source_content_id = SecureRandom.uuid
          english_edition = create(
            :live_edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english",
            link_set_links: [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :draft_edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french",
            link_set_links: [
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
            expect(actual_titles).to eq(expected_titles)
          end
        end

        it "doesn't include any reverse link if none are live" do
          target_edition = create(:live_edition)

          source_content_id = SecureRandom.uuid
          create(
            :draft_edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english",
            link_set_links: [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :draft_edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french",
            link_set_links: [
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
            expect(actual_titles).to eq(expected_titles)
          end
        end
      end

      context "when the link kind is edition_links" do
        it "doesn't default to including a (live) 'en' reverse link when the locale-matching one is draft" do
          target_edition = create(:live_edition)

          source_content_id = SecureRandom.uuid
          create(
            :live_edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english",
            edition_links: [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :draft_edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french",
            edition_links: [
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
            expect(actual_titles).to eq([])
          end
        end
      end
    end

    context "when the reverse linked Edition with matching locale is unpublished" do
      %i[link_set_links edition_links].each do |links_kind|
        context "when the link kind is #{links_kind}" do
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
              expect(actual_titles).to eq(expected_titles)
            end
          end
        end
      end

      context "when the link kind is link_set_links" do
        it "defaults to including a (not-unpublished) 'en' reverse link when the better-matching one isn't a permitted link_type" do
          target_edition = create(:live_edition)

          source_content_id = SecureRandom.uuid
          english_edition = create(
            :live_edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english, published, test link",
            link_set_links: [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :withdrawn_unpublished_edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french, withdrawn, test link",
            link_set_links: [
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
            expect(actual_titles).to eq(expected_titles)
          end
        end
      end

      context "when the link kind is edition_links" do
        it "doesn't default to including a (not-unpublished) 'en' reverse link when the better-matching one isn't a permitted link_type" do
          target_edition = create(:live_edition)

          source_content_id = SecureRandom.uuid
          create(
            :live_edition,
            document: create(:document, locale: "en", content_id: source_content_id),
            title: "english, published, test link",
            edition_links: [
              { link_type: "test_link", target_content_id: target_edition.content_id },
            ],
          )
          create(
            :withdrawn_unpublished_edition,
            document: create(:document, locale: "fr", content_id: source_content_id),
            title: "french, withdrawn, test link",
            edition_links: [
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
            expect(actual_titles).to eq([])
          end
        end
      end
    end
  end
end
