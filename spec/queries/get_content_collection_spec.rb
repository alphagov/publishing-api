require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  context "document_type" do
    before do
      create(:draft_edition,
             base_path: "/a",
             document_type: "topic",
             schema_name: "topic")
      create(:draft_edition,
             base_path: "/b",
             document_type: "topic",
             schema_name: "topic")
      create(:draft_edition,
             base_path: "/c",
             document_type: "mainstream_browse_page",
             schema_name: "mainstream_browse_page")
      create(:draft_edition,
             base_path: "/d",
             document_type: "another_type",
             schema_name: "another_type")
    end

    it "returns the requested fields for all editions" do
      expect(Queries::GetContentCollection.new(
        fields: %w[base_path],
      ).call).to match_array([
        hash_including("base_path" => "/a"),
        hash_including("base_path" => "/b"),
        hash_including("base_path" => "/c"),
        hash_including("base_path" => "/d"),
      ])
    end

    it "returns the editions matching the type" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path locale publication_state],
      ).call).to match_array([
        hash_including("base_path" => "/a", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/b", "publication_state" => "draft", "locale" => "en"),
      ])
    end

    it "returns the editions matching all types when given an array" do
      expect(Queries::GetContentCollection.new(
        document_types: %w[topic mainstream_browse_page],
        fields: %w[base_path locale publication_state],
      ).call).to match_array([
        hash_including("base_path" => "/a", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/b", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/c", "publication_state" => "draft", "locale" => "en"),
      ])
    end
  end

  it "returns the editions of the given format, and placeholder_format" do
    create(:draft_edition,
           base_path: "/a",
           document_type: "topic",
           schema_name: "topic")
    create(:draft_edition,
           base_path: "/b",
           document_type: "placeholder_topic",
           schema_name: "placeholder_topic")

    expect(Queries::GetContentCollection.new(
      document_types: "topic",
      fields: %w[base_path publication_state],
    ).call).to match_array([
      hash_including("base_path" => "/a", "publication_state" => "draft"),
      hash_including("base_path" => "/b", "publication_state" => "draft"),
    ])
  end

  it "includes the publishing state of the item" do
    create(:draft_edition,
           base_path: "/draft",
           document_type: "topic",
           schema_name: "topic")
    create(:live_edition,
           base_path: "/live",
           document_type: "topic",
           schema_name: "topic")

    expect(Queries::GetContentCollection.new(
      document_types: "topic",
      fields: %w[base_path publication_state],
    ).call).to match_array([
      hash_including("base_path" => "/draft", "publication_state" => "draft"),
      hash_including("base_path" => "/live", "publication_state" => "published"),
    ])
  end

  context "for unpublished content" do
    it "can include information about the unpublishing" do
      edition = create(
        :unpublished_edition,
        document_type: "topic",
      )
      unpublishing = Unpublishing.find_by(edition: edition)

      expect(
        Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[base_path publication_state unpublishing],
        ).call,
      ).to match_array(
        [
          hash_including(
            "unpublishing" => hash_including(
              "explanation" => unpublishing.explanation,
              "type" => unpublishing.type,
              "alternative_path" => unpublishing.alternative_path,
              "unpublished_at" => unpublishing.unpublished_at,
            ),
          ),
        ],
      )
    end
  end

  context "when there's no items for the format" do
    it "returns an empty array" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path],
      ).call.to_a).to eq([])
    end
  end

  context "when unknown fields are requested" do
    it "raises an error" do
      expect {
        Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[not_existing],
        ).call
      }.to raise_error(CommandError)
    end
  end

  context "filtering by publishing_app" do
    before do
      create(:draft_edition,
             base_path: "/a",
             document_type: "topic",
             schema_name: "topic",
             publishing_app: "publisher")
      create(:draft_edition,
             base_path: "/b",
             document_type: "topic",
             schema_name: "topic",
             publishing_app: "publisher")
      create(:draft_edition,
             base_path: "/c",
             document_type: "topic",
             schema_name: "topic",
             publishing_app: "whitehall")
    end

    it "returns items corresponding to the publishing_app parameter if present" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[publishing_app publication_state],
        filters: { publishing_app: "publisher" },
      ).call).to match_array([
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[publishing_app publication_state],
      ).call).to match_array([
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "whitehall", "publication_state" => "draft"),
      ])
    end
  end

  describe "the locale filter parameter" do
    before do
      create(:draft_edition,
             document: create(:document, locale: "en"),
             base_path: "/content.en",
             document_type: "topic",
             schema_name: "topic")
      create(:draft_edition,
             document: create(:document, locale: "ar"),
             base_path: "/content.ar",
             document_type: "topic",
             schema_name: "topic")
      create(:live_edition,
             document: create(:document, locale: "en"),
             base_path: "/content.en",
             document_type: "topic",
             schema_name: "topic")
      create(:live_edition,
             document: create(:document, locale: "ar"),
             base_path: "/content.ar",
             document_type: "topic",
             schema_name: "topic")
    end

    it "returns the editions filtered by 'en' locale by default" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path publication_state],
      ).call).to match_array([
        hash_including("base_path" => "/content.en", "publication_state" => "draft"),
        hash_including("base_path" => "/content.en", "publication_state" => "published"),
      ])
    end

    it "returns the editions filtered by locale parameter" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path publication_state],
        filters: { locale: "ar" },
      ).call).to match_array([
        hash_including("base_path" => "/content.ar", "publication_state" => "draft"),
        hash_including("base_path" => "/content.ar", "publication_state" => "published"),
      ])
    end

    it "returns all editions if the locale parameter is 'all'" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path publication_state],
        filters: { locale: "all" },
      ).call).to match_array([
        hash_including("base_path" => "/content.en", "publication_state" => "draft"),
        hash_including("base_path" => "/content.ar", "publication_state" => "draft"),
        hash_including("base_path" => "/content.en", "publication_state" => "published"),
        hash_including("base_path" => "/content.ar", "publication_state" => "published"),
      ])
    end
  end

  describe "filtering by links" do
    let(:someorg_content_id) { SecureRandom.uuid }

    before do
      otherorg_content_id = SecureRandom.uuid
      draft_1_content_id = SecureRandom.uuid
      draft_2_content_id = SecureRandom.uuid
      live_1_content_id = SecureRandom.uuid

      create(:draft_edition,
             document: create(:document, content_id: draft_1_content_id),
             base_path: "/foo",
             publishing_app: "specialist-publisher")

      create(:draft_edition,
             document: create(:document, content_id: draft_2_content_id),
             base_path: "/bar")

      create(:live_edition,
             document: create(:document, content_id: live_1_content_id),
             base_path: "/baz")

      link_set1 = create(:link_set, content_id: draft_1_content_id)
      link_set2 = create(:link_set, content_id: draft_2_content_id)
      link_set3 = create(:link_set, content_id: live_1_content_id)

      create(:link, link_set: link_set1, target_content_id: someorg_content_id)
      create(:link, link_set: link_set2, target_content_id: otherorg_content_id)
      create(:link, link_set: link_set3, target_content_id: someorg_content_id)
    end

    it "filters editions by organisation" do
      result = Queries::GetContentCollection.new(
        filters: { links: { organisations: someorg_content_id } },
        fields: %w[base_path],
      ).call

      expect(result).to match_array([
        hash_including("base_path" => "/foo"),
        hash_including("base_path" => "/baz"),
      ])
    end

    it "filters editions by organisation and other filters" do
      result = Queries::GetContentCollection.new(
        filters: {
          organisation: someorg_content_id,
          publishing_app: "specialist-publisher",
        },
        fields: %w[base_path],
      ).call

      expect(result).to match_array([hash_including("base_path" => "/foo")])
    end
  end

  describe "filtering by state" do
    before do
      create(:draft_edition, base_path: "/draft")
      create(:live_edition, base_path: "/published")
      create(:unpublished_edition, base_path: "/unpublished")
    end

    it "returns all content if no filter is provided" do
      results = Queries::GetContentCollection.new(
        fields: %w[base_path],
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
        hash_including("base_path" => "/unpublished"),
      ])

      results = Queries::GetContentCollection.new(
        filters: { states: [] }, fields: %w[base_path],
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
        hash_including("base_path" => "/unpublished"),
      ])
    end

    it "returns content filtered by the provided states" do
      results = Queries::GetContentCollection.new(
        fields: %w[base_path],
        filters: { states: %w[draft published] },
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
      ])
    end
  end

  context "when details hash is requested" do
    before do
      create(:draft_edition,
             base_path: "/z",
             details: { foo: :bar },
             document_type: "topic",
             schema_name: "topic",
             publishing_app: "publisher")
      create(:draft_edition,
             base_path: "/b",
             details: { baz: :bat },
             document_type: "placeholder_topic",
             schema_name: "placeholder_topic",
             publishing_app: "publisher")
    end
    it "returns the details hash" do
      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[details publication_state],
        filters: { publishing_app: "publisher" },
      ).call).to match_array([
        hash_including("details" => { "foo" => "bar" }, "publication_state" => "draft"),
        hash_including("details" => { "baz" => "bat" }, "publication_state" => "draft"),
      ])
    end
  end

  describe "search_fields" do
    before do
      create(:live_edition,
             base_path: "/bar/foo",
             document_type: "topic",
             schema_name: "topic",
             title: "Baz",
             details: {
               body: "A page about windows.",
               internal_name: "newtopic",
             })
      create(:live_edition,
             base_path: "/baz",
             document_type: "topic",
             schema_name: "topic",
             title: "zip",
             description: "foo",
             details: {
               body: "A page all about doors.",
               internal_name: "baz",
             })
    end

    let(:search_in) { nil }

    subject do
      Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path],
        search_query: search_query,
        search_in: search_in,
      )
    end

    context "base_path and title" do
      let(:search_query) { "baz" }
      it "finds the edition" do
        expect(subject.call.map(&:to_hash)).to match_array([{ "base_path" => "/bar/foo" }, { "base_path" => "/baz" }])
      end
    end

    context "title" do
      let(:search_query) { "zip" }
      it "finds the edition" do
        expect(subject.call.map(&:to_hash)).to eq([{ "base_path" => "/baz" }])
      end
    end

    context "search in" do
      context "with a single nested field" do
        let(:search_in) { ["details.body"] }
        let(:search_query) { "doors" }
        it "finds the edition" do
          expect(subject.call.map(&:to_hash)).to eq([{ "base_path" => "/baz" }])
        end
      end

      context "with multiple nested fields" do
        let(:search_in) { ["details.body", "details.internal_name"] }
        let(:search_query) { "newtopic" }
        it "finds the edition" do
          expect(subject.call.map(&:to_hash)).to eq([{ "base_path" => "/bar/foo" }])
        end
      end

      context "with a mixture of nested and non-nested fields" do
        let(:search_in) { ["title", "details.internal_name"] }
        let(:search_query) { "baz" }
        it "finds the edition" do
          expect(subject.call.map(&:to_hash)).to match_array([
            { "base_path" => "/bar/foo" },
            { "base_path" => "/baz" },
          ])
        end
      end

      context "with invalid top-level fields" do
        let(:search_in) { %w[nonexistent_field] }
        let(:search_query) { "baz" }
        it "raises a CommandError" do
          expect { subject.call }.to raise_error(CommandError)
        end
      end

      context "with a nested field as a top-level fields" do
        let(:search_in) { %w[details] }
        let(:search_query) { "baz" }
        it "raises a CommandError" do
          expect { subject.call }.to raise_error(CommandError)
        end
      end

      context "with description among the fields" do
        let(:search_in) { %w[description] }
        let(:search_query) { "foo" }
        it "finds the edition" do
          expect(subject.call.map(&:to_hash)).to eq([{ "base_path" => "/baz" }])
        end
      end

      context "with fields nested more than one level deep" do
        let(:search_in) { ["details.foo.bar"] }
        let(:search_query) { "baz" }
        it "raises a CommandError" do
          expect { subject.call }.to raise_error(CommandError)
        end

        context "with SQL injection in nested fields" do
          let(:search_in) { ["details.foo' = '') OR 1=1--"] }
          let(:search_query) { "baz" }
          it "returns an empty result" do
            expect(subject.call.to_a).to eq([])
          end
        end
      end
    end
  end

  describe "pagination" do
    context "with multiple editions" do
      before do
        [
          ["/a", "2010-01-06"], ["/b", "2010-01-05"], ["/c", "2010-01-04"], ["/d", "2010-01-03"]
        ].each do |(base_path, public_updated_at)|
          create(:draft_edition,
                 base_path: base_path,
                 document_type: "topic",
                 schema_name: "topic",
                 public_updated_at: public_updated_at)
        end
        [
          ["/live1", "2010-01-02"], ["/live2", "2010-01-01"]
        ].each do |(base_path, public_updated_at)|
          create(:live_edition,
                 base_path: base_path,
                 document_type: "topic",
                 schema_name: "topic",
                 public_updated_at: public_updated_at)
        end
      end

      it "limits the results returned" do
        editions = Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[publishing_app],
          pagination: Pagination.new(offset: 0, per_page: 3),
        ).call

        expect(editions.count).to eq(3)
      end

      it "fetches results from a specified index" do
        editions = Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[base_path],
          pagination: Pagination.new(offset: 1, per_page: 2),
        ).call

        expect(editions.first["base_path"]).to eq("/b")
      end

      it "when per_page is higher than results we only receive remaining editions" do
        editions = Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[base_path],
          pagination: Pagination.new(offset: 3, per_page: 8),
        ).call.to_a

        expect(editions.first["base_path"]).to eq("/d")
        expect(editions.last["base_path"]).to eq("/live2")
      end

      it "returns all items when no pagination params are specified" do
        editions = Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[publishing_app],
        ).call

        expect(editions.count).to eq(6)
      end
    end
  end

  describe "result order" do
    before do
      create(:edition, base_path: "/c4", title: "D", public_updated_at: "2014-06-14")
      create(:edition, base_path: "/c1", title: "A", public_updated_at: "2014-06-13")
      create(:edition, base_path: "/c3", title: "C", public_updated_at: "2014-06-17")
      create(:edition, base_path: "/c2", title: "B", public_updated_at: "2014-06-15")
    end

    it "returns editions in default order" do
      editions = Queries::GetContentCollection.new(
        fields: %w[public_updated_at],
      ).call.to_a

      expect(editions.count).to eq(4)
      expect(editions.first["public_updated_at"]).to eq("2014-06-17T00:00:00Z")
      expect(editions.last["public_updated_at"]).to eq("2014-06-13T00:00:00Z")
    end

    it "returns paginated editions in default order" do
      editions = Queries::GetContentCollection.new(
        fields: %w[public_updated_at],
        pagination: Pagination.new(offset: 2, per_page: 4),
      ).call.to_a

      expect(editions.first["public_updated_at"]).to eq("2014-06-14T00:00:00Z")
      expect(editions.last["public_updated_at"]).to eq("2014-06-13T00:00:00Z")
    end
  end

  describe "#total" do
    it "returns the number of editions" do
      create(:edition, base_path: "/a", schema_name: "topic", document_type: "topic")
      create(:edition, base_path: "/b", schema_name: "topic", document_type: "topic")

      expect(Queries::GetContentCollection.new(
        document_types: "topic",
        fields: %w[base_path locale publication_state],
      ).total).to eq(2)
    end

    context "when there are multiple versions of the same edition" do
      before do
        document = create(:document)

        create(:live_edition,
               document: document,
               document_type: "topic",
               schema_name: "topic",
               user_facing_version: 1)

        create(:draft_edition,
               document: document,
               document_type: "topic",
               schema_name: "topic",
               user_facing_version: 2)
      end

      it "returns the latest item only" do
        expect(Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[base_path locale publication_state],
        ).total).to eq(1)

        expect(Queries::GetContentCollection.new(
          document_types: "topic",
          fields: %w[base_path locale publication_state],
        ).call.first["publication_state"]).to eq("draft")
      end
    end
  end
end
