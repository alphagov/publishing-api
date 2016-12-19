require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  context "document_type" do
    before do
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/a',
        document_type: 'topic',
        schema_name: 'topic',
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/b',
        document_type: 'topic',
        schema_name: 'topic',
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/c',
        document_type: 'mainstream_browse_page',
        schema_name: 'mainstream_browse_page',
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/d',
        document_type: 'another_type',
        schema_name: 'another_type',
      )
    end

    it "returns the content items matching the type" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(base_path locale publication_state),
      ).call).to match_array([
        hash_including("base_path" => "/a", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/b", "publication_state" => "draft", "locale" => "en"),
      ])
    end

    it "returns the content items matching all types when given an array" do
      expect(Queries::GetContentCollection.new(
        document_types: %w(topic mainstream_browse_page),
        fields: %w(base_path locale publication_state),
      ).call).to match_array([
        hash_including("base_path" => "/a", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/b", "publication_state" => "draft", "locale" => "en"),
        hash_including("base_path" => "/c", "publication_state" => "draft", "locale" => "en"),
      ])
    end
  end

  it "returns the content items of the given format, and placeholder_format" do
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/a',
      document_type: 'topic',
      schema_name: 'topic',
    )
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/b',
      document_type: 'placeholder_topic',
      schema_name: 'placeholder_topic'
    )

    expect(Queries::GetContentCollection.new(
      document_types: 'topic',
      fields: %w(base_path publication_state),
    ).call).to match_array([
      hash_including("base_path" => "/a", "publication_state" => "draft"),
      hash_including("base_path" => "/b", "publication_state" => "draft"),
    ])
  end

  it "includes the publishing state of the item" do
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/draft',
      document_type: 'topic',
      schema_name: 'topic',
    )
    FactoryGirl.create(
      :live_content_item,
      base_path: '/live',
      document_type: 'topic',
      schema_name: 'topic',
    )

    expect(Queries::GetContentCollection.new(
      document_types: 'topic',
      fields: %w(base_path publication_state),
    ).call).to match_array([
      hash_including("base_path" => "/draft", "publication_state" => "draft"),
      hash_including("base_path" => "/live", "publication_state" => "published"),
    ])
  end

  context "when there's no items for the format" do
    it "returns an empty array" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: ['base_path'],
      ).call.to_a).to eq([])
    end
  end

  context "when unknown fields are requested" do
    it "raises an error" do
      expect {
        Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: ['not_existing'],
        ).call
      }.to raise_error(CommandError)
    end
  end

  context "filtering by publishing_app" do
    before do
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/a',
        document_type: 'topic',
        schema_name: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/b',
        document_type: 'topic',
        schema_name: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/c',
        document_type: 'topic',
        schema_name: 'topic',
        publishing_app: 'whitehall'
      )
    end

    it "returns items corresponding to the publishing_app parameter if present" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(publishing_app publication_state),
        filters: { publishing_app: 'publisher' }
      ).call).to match_array([
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "publisher", "publication_state" => "draft")
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(publishing_app publication_state)
      ).call).to match_array([
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "whitehall", "publication_state" => "draft")
      ])
    end
  end

  describe "the locale filter parameter" do
    before do
      FactoryGirl.create(:draft_content_item, base_path: '/content.en', document_type: 'topic', schema_name: 'topic', locale: 'en')
      FactoryGirl.create(:draft_content_item, base_path: '/content.ar', document_type: 'topic', schema_name: 'topic', locale: 'ar')
      FactoryGirl.create(:live_content_item, base_path: '/content.en', document_type: 'topic', schema_name: 'topic', locale: 'en')
      FactoryGirl.create(:live_content_item, base_path: '/content.ar', document_type: 'topic', schema_name: 'topic', locale: 'ar')
    end

    it "returns the content items filtered by 'en' locale by default" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(base_path publication_state),
      ).call).to match_array([
        hash_including("base_path" => "/content.en", "publication_state" => "draft"),
        hash_including("base_path" => "/content.en", "publication_state" => "published"),
      ])
    end

    it "returns the content items filtered by locale parameter" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(base_path publication_state),
        filters: { locale: 'ar' },
      ).call).to match_array([
        hash_including("base_path" => "/content.ar", "publication_state" => "draft"),
        hash_including("base_path" => "/content.ar", "publication_state" => "published"),
      ])
    end

    it "returns all content items if the locale parameter is 'all'" do
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(base_path publication_state),
        filters: { locale: 'all' },
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

      FactoryGirl.create(
        :draft_content_item,
        content_id: draft_1_content_id,
        base_path: "/foo",
        publishing_app: "specialist-publisher"
      )

      FactoryGirl.create(
        :draft_content_item,
        content_id: draft_2_content_id,
        base_path: "/bar"
      )

      FactoryGirl.create(
        :live_content_item,
        content_id: live_1_content_id,
        base_path: "/baz"
      )

      link_set_1 = FactoryGirl.create(:link_set, content_id: draft_1_content_id)
      link_set_2 = FactoryGirl.create(:link_set, content_id: draft_2_content_id)
      link_set_3 = FactoryGirl.create(:link_set, content_id: live_1_content_id)

      FactoryGirl.create(:link, link_set: link_set_1, target_content_id: someorg_content_id)
      FactoryGirl.create(:link, link_set: link_set_2, target_content_id: otherorg_content_id)
      FactoryGirl.create(:link, link_set: link_set_3, target_content_id: someorg_content_id)
    end

    it "filters content items by organisation" do
      result = Queries::GetContentCollection.new(
        document_types: "guide",
        filters: { links: { organisations: someorg_content_id } },
        fields: %w(base_path),
      ).call

      expect(result).to match_array([
        hash_including("base_path" => "/foo"),
        hash_including("base_path" => "/baz"),
      ])
    end

    it "filters content items by organisation and other filters" do
      result = Queries::GetContentCollection.new(
        document_types: "guide",
        filters: {
          organisation: someorg_content_id,
          publishing_app: "specialist-publisher",
        },
        fields: %w(base_path),
      ).call

      expect(result).to match_array([hash_including("base_path" => "/foo")])
    end
  end

  describe "filtering by state" do
    before do
      FactoryGirl.create(:draft_content_item, base_path: "/draft")
      FactoryGirl.create(:live_content_item, base_path: "/published")
      FactoryGirl.create(:unpublished_content_item, base_path: "/unpublished")
    end

    it "returns all content if no filter is provided" do
      results = Queries::GetContentCollection.new(
        document_types: "guide", fields: %w(base_path)
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
        hash_including("base_path" => "/unpublished"),
      ])

      results = Queries::GetContentCollection.new(
        document_types: "guide", filters: { states: [] }, fields: %w(base_path)
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
        hash_including("base_path" => "/unpublished"),
      ])
    end

    it "returns content filtered by the provided states" do
      results = Queries::GetContentCollection.new(
        document_types: "guide",
        fields: %w(base_path),
        filters: { states: %w(draft published) },
      ).call

      expect(results).to match_array([
        hash_including("base_path" => "/draft"),
        hash_including("base_path" => "/published"),
      ])
    end
  end

  context "when details hash is requested" do
    it "returns the details hash" do
      FactoryGirl.create(:draft_content_item, base_path: '/z', details: { foo: :bar }, document_type: 'topic', schema_name: 'topic', publishing_app: 'publisher')
      FactoryGirl.create(:draft_content_item, base_path: '/b', details: { baz: :bat }, document_type: 'placeholder_topic', schema_name: 'placeholder_topic', publishing_app: 'publisher')
      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(details publication_state),
        filters: { publishing_app: 'publisher' }
      ).call).to match_array([
        hash_including("details" => { "foo" => "bar" }, "publication_state" => "draft"),
        hash_including("details" => { "baz" => "bat" }, "publication_state" => "draft"),
      ])
    end
  end

  describe "search_fields" do
    let!(:content_item_foo) { FactoryGirl.create(:live_content_item, base_path: '/bar/foo', document_type: 'topic', schema_name: 'topic', title: "Baz") }
    let!(:content_item_zip) { FactoryGirl.create(:live_content_item, base_path: '/baz', document_type: 'topic', schema_name: 'topic', title: 'zip') }
    subject do
      Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: ['base_path'],
        search_query: search_query
      )
    end

    context "base_path and title" do
      let(:search_query) { "baz" }
      it "finds the content item" do
        expect(subject.call.map(&:to_hash)).to match_array([{ "base_path" => "/bar/foo" }, { "base_path" => "/baz" }])
      end
    end

    context "title" do
      let(:search_query) { "zip" }
      it "finds the content item" do
        expect(subject.call.map(&:to_hash)).to eq([{ "base_path" => "/baz" }])
      end
    end
  end

  describe "pagination" do
    context "with multiple content items" do
      before do
        FactoryGirl.create(:draft_content_item, base_path: '/a', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-06")
        FactoryGirl.create(:draft_content_item, base_path: '/b', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-05")
        FactoryGirl.create(:draft_content_item, base_path: '/c', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-04")
        FactoryGirl.create(:draft_content_item, base_path: '/d', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-03")
        FactoryGirl.create(:live_content_item, base_path: '/live1', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-02")
        FactoryGirl.create(:live_content_item, base_path: '/live2', document_type: 'topic', schema_name: 'topic', public_updated_at: "2010-01-01")
      end

      it "limits the results returned" do
        content_items = Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: ['publishing_app'],
          pagination: Pagination.new(offset: 0, per_page: 3)
        ).call

        expect(content_items.count).to eq(3)
      end

      it "fetches results from a specified index" do
        content_items = Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: ['base_path'],
          pagination: Pagination.new(offset: 1, per_page: 2)
        ).call

        expect(content_items.first['base_path']).to eq('/b')
      end

      it "when per_page is higher than results we only receive remaining content items" do
        content_items = Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: ['base_path'],
          pagination: Pagination.new(offset: 3, per_page: 8)
        ).call.to_a

        expect(content_items.first['base_path']).to eq('/d')
        expect(content_items.last['base_path']).to eq('/live2')
      end

      it "returns all items when no pagination params are specified" do
        content_items = Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: ['publishing_app'],
        ).call

        expect(content_items.count).to eq(6)
      end
    end
  end

  describe "result order" do
    before do
      FactoryGirl.create(:content_item, base_path: "/c4", title: 'D', public_updated_at: DateTime.parse('2014-06-14'))
      FactoryGirl.create(:content_item, base_path: "/c1", title: 'A', public_updated_at: DateTime.parse('2014-06-13'))
      FactoryGirl.create(:content_item, base_path: "/c3", title: 'C', public_updated_at: DateTime.parse('2014-06-17'))
      FactoryGirl.create(:content_item, base_path: "/c2", title: 'B', public_updated_at: DateTime.parse('2014-06-15'))
    end

    it "returns content items in default order" do
      content_items = Queries::GetContentCollection.new(
        document_types: 'guide',
        fields: %w(public_updated_at),
      ).call.to_a

      expect(content_items.count).to eq(4)
      expect(content_items.first['public_updated_at']).to eq('2014-06-17T00:00:00Z')
      expect(content_items.last['public_updated_at']).to eq('2014-06-13T00:00:00Z')
    end

    it "returns paginated content items in default order" do
      content_items = Queries::GetContentCollection.new(
        document_types: 'guide',
        fields: %w(public_updated_at),
        pagination: Pagination.new(offset: 2, per_page: 4)
      ).call.to_a

      expect(content_items.first['public_updated_at']).to eq('2014-06-14T00:00:00Z')
      expect(content_items.last['public_updated_at']).to eq('2014-06-13T00:00:00Z')
    end
  end

  describe "#total" do
    it "returns the number of content items" do
      FactoryGirl.create(:content_item, base_path: '/a', schema_name: 'topic', document_type: 'topic')
      FactoryGirl.create(:content_item, base_path: '/b', schema_name: 'topic', document_type: 'topic')

      expect(Queries::GetContentCollection.new(
        document_types: 'topic',
        fields: %w(base_path locale publication_state),
      ).total).to eq(2)
    end

    context "when there are multiple versions of the same content item" do
      before do
        content_id = SecureRandom.uuid

        FactoryGirl.create(
          :live_content_item,
          content_id: content_id,
          document_type: 'topic',
          schema_name: 'topic',
          user_facing_version: 1,
        )

        FactoryGirl.create(
          :content_item,
          content_id: content_id,
          document_type: 'topic',
          schema_name: 'topic',
          state: "draft",
          user_facing_version: 2,
        )
      end

      it "returns the latest item only" do
        expect(Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: %w(base_path locale publication_state),
        ).total).to eq(1)

        expect(Queries::GetContentCollection.new(
          document_types: 'topic',
          fields: %w(base_path locale publication_state),
        ).call.first["publication_state"]).to eq("draft")
      end
    end
  end
end
