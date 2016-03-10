require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  it "returns the content items of the given format" do
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/a',
      format: 'topic',
    )
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/b',
      format: 'topic',
    )
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/c',
      format: 'mainstream_browse_page',
    )

    expect(Queries::GetContentCollection.new(
      document_type: 'topic',
      fields: %w(base_path locale publication_state),
    ).call).to match_array([
      hash_including("base_path" => "/a", "publication_state" => "draft", "locale" => "en"),
      hash_including("base_path" => "/b", "publication_state" => "draft", "locale" => "en"),
    ])
  end

  it "returns the content items of the given format, and placeholder_format" do
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/a',
      format: 'topic'
    )
    FactoryGirl.create(
      :draft_content_item,
      base_path: '/b',
      format: 'placeholder_topic'
    )

    expect(Queries::GetContentCollection.new(
      document_type: 'topic',
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
      format: 'topic'
    )
    FactoryGirl.create(
      :live_content_item,
      base_path: '/live',
      format: 'topic'
    )

    expect(Queries::GetContentCollection.new(
      document_type: 'topic',
      fields: %w(base_path publication_state),
    ).call).to match_array([
      hash_including("base_path" => "/draft", "publication_state" => "draft"),
      hash_including("base_path" => "/live", "publication_state" => "live"),
    ])
  end

  context "when there's no items for the format" do
    it "returns an empty array" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: ['base_path'],
      ).call).to eq([])
    end
  end

  context "when unknown fields are requested" do
    it "raises an error" do
      expect {
        Queries::GetContentCollection.new(
          document_type: 'topic',
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
        format: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/b',
        format: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        base_path: '/c',
        format: 'topic',
        publishing_app: 'whitehall'
      )
    end

    it "returns items corresponding to the publishing_app parameter if present" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: %w(publishing_app publication_state),
        publishing_app: 'publisher'
      ).call).to match_array([
        hash_including("publishing_app" => "publisher", "publication_state" => "draft"),
        hash_including("publishing_app" => "publisher", "publication_state" => "draft")
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
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
      FactoryGirl.create(:draft_content_item, base_path: '/content.en', format: 'topic', locale: 'en')
      FactoryGirl.create(:draft_content_item, base_path: '/content.ar', format: 'topic', locale: 'ar')
      FactoryGirl.create(:live_content_item, base_path: '/content.en', format: 'topic', locale: 'en')
      FactoryGirl.create(:live_content_item, base_path: '/content.ar', format: 'topic', locale: 'ar')
    end

    it "returns the content items filtered by 'en' locale by default" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: %w(base_path publication_state),
      ).call).to match_array([
        hash_including("base_path" => "/content.en", "publication_state" => "draft"),
        hash_including("base_path" => "/content.en", "publication_state" => "live"),
      ])
    end

    it "returns the content items filtered by locale parameter" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: %w(base_path publication_state),
        locale: 'ar',
      ).call).to match_array([
        hash_including("base_path" => "/content.ar", "publication_state" => "draft"),
        hash_including("base_path" => "/content.ar", "publication_state" => "live"),
      ])
    end

    it "returns all content items if the locale parameter is 'all'" do
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: %w(base_path publication_state),
        locale: 'all',
      ).call).to match_array([
        hash_including("base_path" => "/content.en", "publication_state" => "draft"),
        hash_including("base_path" => "/content.ar", "publication_state" => "draft"),
        hash_including("base_path" => "/content.en", "publication_state" => "live"),
        hash_including("base_path" => "/content.ar", "publication_state" => "live"),
      ])
    end
  end

  context "when details hash is requested" do
    it "returns the details hash" do
      create(:draft_content_item, base_path: '/z', details: { foo: :bar }, format: 'topic', publishing_app: 'publisher')
      create(:draft_content_item, base_path: '/b', details: { baz: :bat }, format: 'placeholder_topic', publishing_app: 'publisher')
      expect(Queries::GetContentCollection.new(
        document_type: 'topic',
        fields: %w(details publication_state),
        publishing_app: 'publisher'
      ).call).to match_array([
        hash_including("details" => { "foo" => "bar" }, "publication_state" => "draft"),
        hash_including("details" => { "baz" => "bat" }, "publication_state" => "draft"),
      ])
    end
  end

  describe "pagination" do
    context "with multiple content items" do
      before do
        create(:draft_content_item, base_path: '/a', format: 'topic', public_updated_at: "2010-01-06")
        create(:draft_content_item, base_path: '/b', format: 'topic', public_updated_at: "2010-01-05")
        create(:draft_content_item, base_path: '/c', format: 'topic', public_updated_at: "2010-01-04")
        create(:draft_content_item, base_path: '/d', format: 'topic', public_updated_at: "2010-01-03")
        create(:live_content_item, base_path: '/live1', format: 'topic', public_updated_at: "2010-01-02")
        create(:live_content_item, base_path: '/live2', format: 'topic', public_updated_at: "2010-01-01")
      end

      it "limits the results returned" do
        content_items = Queries::GetContentCollection.new(
          document_type: 'topic',
          fields: ['publishing_app'],
          pagination: Pagination.new(start: 0, page_size: 3)
        ).call

        expect(content_items.size).to eq(3)
      end

      it "fetches results from a specified index" do
        content_items = Queries::GetContentCollection.new(
          document_type: 'topic',
          fields: ['base_path'],
          pagination: Pagination.new(start: 1, page_size: 2)
        ).call

        expect(content_items.first['base_path']).to eq('/b')
      end

      it "when page_size is higher than results we only receive remaining content items" do
        content_items = Queries::GetContentCollection.new(
          document_type: 'topic',
          fields: ['base_path'],
          pagination: Pagination.new(start: 3, page_size: 8)
        ).call

        expect(content_items.first['base_path']).to eq('/d')
        expect(content_items.last['base_path']).to eq('/live2')
      end

      it "returns all items when no pagination params are specified" do
        content_items = Queries::GetContentCollection.new(
          document_type: 'topic',
          fields: ['publishing_app'],
        ).call

        expect(content_items.size).to eq(6)
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
        document_type: 'guide',
        fields: %w(public_updated_at),
      ).call

      expect(content_items.size).to eq(4)
      expect(content_items.first['public_updated_at']).to eq('2014-06-17 00:00:00')
      expect(content_items.last['public_updated_at']).to eq('2014-06-13 00:00:00')
    end

    it "returns paginated content items in default order" do
      content_items = Queries::GetContentCollection.new(
        document_type: 'guide',
        fields: %w(public_updated_at),
        pagination: Pagination.new(start: 2, page_size: 4)
      ).call

      expect(content_items.first['public_updated_at']).to eq('2014-06-14 00:00:00')
      expect(content_items.last['public_updated_at']).to eq('2014-06-13 00:00:00')
    end
  end
end
