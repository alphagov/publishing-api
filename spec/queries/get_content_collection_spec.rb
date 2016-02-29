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
      content_format: 'topic',
      fields: %w(base_path locale publication_state),
    ).call).to match_array([
      { "base_path" => "/a", "publication_state" => "draft", "locale" => "en" },
      { "base_path" => "/b", "publication_state" => "draft", "locale" => "en" },
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
      content_format: 'topic',
      fields: %w(base_path publication_state),
    ).call).to match_array([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
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
      content_format: 'topic',
      fields: %w(base_path publication_state),
    ).call).to eq([
      { "base_path" => "/draft", "publication_state" => "draft" },
      { "base_path" => "/live", "publication_state" => "live" },
    ])
  end

  context "when there's no items for the format" do
    it "returns an empty array" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['base_path'],
      ).call).to eq([])
    end
  end

  context "when unknown fields are requested" do
    it "raises an error" do
      expect {
        Queries::GetContentCollection.new(
          content_format: 'topic',
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
        content_format: 'topic',
        fields: %w(publishing_app publication_state),
        publishing_app: 'publisher'
      ).call).to match_array([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" }
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: %w(publishing_app publication_state)
      ).call).to match_array([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "whitehall", "publication_state" => "draft" }
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
        content_format: 'topic',
        fields: %w(base_path publication_state),
      ).call).to match_array([
        { "base_path" => "/content.en", "publication_state" => "draft" },
        { "base_path" => "/content.en", "publication_state" => "live" },
      ])
    end

    it "returns the content items filtered by locale parameter" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: %w(base_path publication_state),
        locale: 'ar',
      ).call).to match_array([
        { "base_path" => "/content.ar", "publication_state" => "draft" },
        { "base_path" => "/content.ar", "publication_state" => "live" },
      ])
    end

    it "returns all content items if the locale parameter is 'all'" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: %w(base_path publication_state),
        locale: 'all',
      ).call).to match_array([
        { "base_path" => "/content.en", "publication_state" => "draft" },
        { "base_path" => "/content.ar", "publication_state" => "draft" },
        { "base_path" => "/content.en", "publication_state" => "live" },
        { "base_path" => "/content.ar", "publication_state" => "live" },
      ])
    end
  end

  context "when details hash is requested" do
    it "returns the details hash" do
      create(:draft_content_item, base_path: '/z', details: { foo: :bar }, format: 'topic', publishing_app: 'publisher')
      create(:draft_content_item, base_path: '/b', details: { baz: :bat }, format: 'placeholder_topic', publishing_app: 'publisher')
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: %w(details publication_state),
        publishing_app: 'publisher'
      ).call).to match_array([
        { "details" => { "foo" => "bar" }, "publication_state" => "draft" },
        { "details" => { "baz" => "bat" }, "publication_state" => "draft" }
      ])
    end
  end
end
