RSpec.describe Sources::LinkedToEditionsSource do
  RSpec::Matchers.define :have_links do |link_type|
    def check_links!
      expect(@links).not_to be_empty

      unless expected_titles.nil?
        if @in_any_order
          expect(@actual_titles).to match_array(expected_titles)
        else
          expect(@actual_titles).to eq(expected_titles)
        end
      end
    end

    match do |source_edition|
      GraphQL::Dataloader.with_dataloading do |dataloader|
        request = dataloader.with(
          described_class,
          content_store: source_edition.content_store,
          locale: source_edition.locale,
        ).request([source_edition, link_type])

        @links = request.load
        @actual_titles = @links.map(&:title)

        check_links!
      end
    end

    chain :with_titles, :expected_titles
    chain :in_any_order do
      @in_any_order = true
    end

    failure_message do
      check_links!
    end
  end

  context "when the same source content has a mix of link set links and edition links for the same link type" do
    it "returns only the edition links" do
      target_edition_1 = create(:edition, title: "edition 1, test link, edition link")
      target_edition_2 = create(:edition, title: "edition 2, test link, link set link")

      source_edition = create(:edition,
                              edition_links: [
                                { link_type: "test_link", target_content_id: target_edition_1.content_id },
                              ],
                              link_set_links: [
                                { link_type: "test_link", target_content_id: target_edition_2.content_id },
                              ])

      expected_titles = [target_edition_1.title]
      expect(source_edition).to have_links("test_link").with_titles(expected_titles)
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

        expected_titles = [target_edition_1, target_edition_3].map(&:title)
        expect(source_edition).to have_links("test_link").with_titles(expected_titles).in_any_order
      end

      it "returns links from only the requested content store" do
        target_edition_0 = create(:live_edition, title: "edition 0, live")
        target_edition_1 = create(:draft_edition, title: "edition 1, draft")

        source_edition = create(:draft_edition,
                                links_kind => [
                                  { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                  { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                ])

        expected_titles = [target_edition_1.title]
        expect(source_edition).to have_links("test_link").with_titles(expected_titles)
      end

      it "returns editions in order of their associated link's `position`" do
        target_edition_0 = create(:edition, title: "edition 0, position 1")
        target_edition_1 = create(:edition, title: "edition 1, position 2")
        target_edition_2 = create(:edition, title: "edition 2, position 0")

        source_edition = create(:edition,
                                links_kind => [
                                  { link_type: "test_link", target_content_id: target_edition_0.content_id, position: 1 },
                                  { link_type: "test_link", target_content_id: target_edition_1.content_id, position: 2 },
                                  { link_type: "test_link", target_content_id: target_edition_2.content_id, position: 0 },
                                ])

        expected_titles = [target_edition_2, target_edition_0, target_edition_1].map(&:title)
        expect(source_edition).to have_links("test_link").with_titles(expected_titles)
      end

      context "when links have the same `position`" do
        it "returns editions reverse-ordered by their associated links' `id`" do
          target_edition_0 = create(:edition, title: "edition 0, third link id")
          target_edition_1 = create(:edition, title: "edition 1, first link id")
          target_edition_2 = create(:edition, title: "edition 2, second link id")
          target_edition_3 = create(:edition, title: "edition 3, fourth link id")

          source_edition = create(:edition,
                                  links_kind => [
                                    { link_type: "test_link", target_content_id: target_edition_1.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_2.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_0.content_id, position: 0 },
                                    { link_type: "test_link", target_content_id: target_edition_3.content_id, position: 0 },
                                  ])

          expected_titles = [target_edition_3, target_edition_0, target_edition_2, target_edition_1].map(&:title)
          expect(source_edition).to have_links("test_link").with_titles(expected_titles)
        end
      end

      context "when the linked item is unpublished" do
        context "when the links are of a permitted unpublished link type" do
          it "includes unpublished links when the unpublishing type is withdrawal" do
            target_edition = create(:withdrawn_unpublished_edition, title: "withdrawn edition")

            source_edition = create(:live_edition,
                                    links_kind => [
                                      { link_type: "parent", target_content_id: target_edition.content_id },
                                    ])

            expected_titles = [target_edition.title]
            expect(source_edition).to have_links("parent").with_titles(expected_titles).in_any_order
          end

          it "does not include unpublished links when the unpublishing type is not withdrawal" do
            target_edition_0 = create(:gone_unpublished_edition, title: "edition 0, gone")
            target_edition_1 = create(:redirect_unpublished_edition, title: "edition 1, redirect")
            target_edition_2 = create(:substitute_unpublished_edition, title: "edition 2, substitute")
            target_edition_3 = create(:vanish_unpublished_edition, title: "edition 3, vanish")

            source_edition = create(:live_edition,
                                    links_kind => [
                                      { link_type: "parent", target_content_id: target_edition_0.content_id },
                                      { link_type: "parent", target_content_id: target_edition_1.content_id },
                                      { link_type: "parent", target_content_id: target_edition_2.content_id },
                                      { link_type: "parent", target_content_id: target_edition_3.content_id },
                                    ])

            expect(source_edition).not_to have_links("parent")
          end
        end

        context "when the links aren't of a permitted unpublished link type" do
          it "does not include unpublished links even if the unpublishing type is withdrawal" do
            target_edition_0 = create(:live_edition, title: "edition 0, published")
            target_edition_1 = create(:withdrawn_unpublished_edition, title: "edition 1, withdrawn")

            source_edition = create(:live_edition,
                                    links_kind => [
                                      { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                      { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                    ])

            expected_titles = [target_edition_0.title]
            expect(source_edition).to have_links("test_link").with_titles(expected_titles)
          end

          it "also does not include unpublished links when the unpublishing type is not withdrawal" do
            target_edition_0 = create(:gone_unpublished_edition, title: "edition 0, gone")
            target_edition_1 = create(:redirect_unpublished_edition, title: "edition 1, redirect")
            target_edition_2 = create(:substitute_unpublished_edition, title: "edition 2, substitute")
            target_edition_3 = create(:vanish_unpublished_edition, title: "edition 3, vanish")

            source_edition = create(:live_edition,
                                    links_kind => [
                                      { link_type: "test_link", target_content_id: target_edition_0.content_id },
                                      { link_type: "test_link", target_content_id: target_edition_1.content_id },
                                      { link_type: "test_link", target_content_id: target_edition_2.content_id },
                                      { link_type: "test_link", target_content_id: target_edition_3.content_id },
                                    ])

            expect(source_edition).not_to have_links("test_link")
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
            document: create(:document, locale: "fr"),
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
          )

          expected_titles = [french_edition.title]
          expect(source_edition).to have_links("test_link").with_titles(expected_titles)
        end

        it "includes English language links if there's no better match available" do
          target_content_id = SecureRandom.uuid
          english_edition = create(:edition, document: create(:document, locale: "en", content_id: target_content_id), title: "english edition")
          create(:edition, document: create(:document, locale: "fr", content_id: target_content_id), title: "french edition")

          source_edition = create(
            :edition,
            document: create(:document, locale: "de"),
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
          )

          expected_titles = [english_edition.title]
          expect(source_edition).to have_links("test_link").with_titles(expected_titles)
        end

        it "doesn't include a link if none match the locale or English" do
          target_content_id = SecureRandom.uuid
          create(:edition, document: create(:document, locale: "de", content_id: target_content_id), title: "german")
          create(:edition, document: create(:document, locale: "fr", content_id: target_content_id), title: "french")

          source_edition = create(
            :edition,
            document: create(:document, locale: "hu"),
            links_kind => [
              { link_type: "test_link", target_content_id: },
            ],
          )

          expect(source_edition).not_to have_links("test_link")
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
              document: create(:document, locale: "fr"),
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
            )

            expected_titles = [english_edition.title]
            expect(source_edition).to have_links("test_link").with_titles(expected_titles)
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
              document: create(:document, locale: "fr"),
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
            )

            expect(source_edition).not_to have_links("test_link")
          end
        end

        context "when the linked Edition with matching locale is unpublished" do
          it "includes the link if it's a permitted link_type and there are no competing published links" do
            target_content_id = SecureRandom.uuid
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english, withdrawn, related_statistical_data_sets",
            )
            french_withdrawn_edition = create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french, withdrawn, related_statistical_data_sets",
            )

            source_edition = create(
              :live_edition,
              document: create(:document, locale: "fr"),
              links_kind => [
                { link_type: "related_statistical_data_sets", target_content_id: },
              ],
            )

            expected_titles = [french_withdrawn_edition.title]
            expect(source_edition).to have_links("related_statistical_data_sets").with_titles(expected_titles)
          end

          it "falls back to a published 'en' link even if the locale-matching one is a permitted link_type" do
            target_content_id = SecureRandom.uuid
            english_published_edition = create(
              :live_edition,
              document: create(:document, locale: "en", content_id: target_content_id),
              title: "english, published, related_statistical_data_sets",
            )
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french, withdrawn, related_statistical_data_sets",
            )

            source_edition = create(
              :live_edition,
              document: create(:document, locale: "fr"),
              links_kind => [
                { link_type: "related_statistical_data_sets", target_content_id: },
              ],
            )

            expected_titles = [english_published_edition.title]
            expect(source_edition).to have_links("related_statistical_data_sets").with_titles(expected_titles)
          end

          it "omits a locale-matching link if it isn't a permitted unpublished link_type" do
            target_content_id = SecureRandom.uuid
            create(
              :withdrawn_unpublished_edition,
              document: create(:document, locale: "fr", content_id: target_content_id),
              title: "french, withdrawn, test_link",
            )

            source_edition = create(
              :live_edition,
              document: create(:document, locale: "fr"),
              links_kind => [
                { link_type: "test_link", target_content_id: },
              ],
            )

            expect(source_edition).not_to have_links("test_link")
          end
        end
      end

      it "doesn't include linked editions of non-renderable document types" do
        renderable_edition = create(:edition, title: "renderable edition")
        non_renderable_edition = create(:redirect_edition, title: "non-renderable edition (redirect)")

        source_edition = create(
          :edition,
          links_kind => [
            { link_type: "test_link", target_content_id: renderable_edition.content_id },
            { link_type: "test_link", target_content_id: non_renderable_edition.content_id },
          ],
        )

        expected_titles = [renderable_edition.title]
        expect(source_edition).to have_links("test_link").with_titles(expected_titles)
      end
    end
  end
end
