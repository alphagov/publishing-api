require "rails_helper"

RSpec.describe Queries::GetContentCollection do
  it "returns the content items of the given format" do
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/a',
      format: 'topic',
    )
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/b',
      format: 'topic',
    )
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/c',
      format: 'mainstream_browse_page',
    )

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path', 'locale'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft", "locale" => "en" },
      { "base_path" => "/b", "publication_state" => "draft", "locale" => "en" },
    ])
  end

  it "returns the content items of the given format, and placeholder_format" do
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/a',
      format: 'topic'
    )
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/b',
      format: 'placeholder_topic'
    )

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/a", "publication_state" => "draft" },
      { "base_path" => "/b", "publication_state" => "draft" },
    ])
  end

  it "includes the publishing state of the item" do
    FactoryGirl.create(
      :draft_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/draft',
      format: 'topic'
    )
    FactoryGirl.create(
      :live_content_item,
      :with_lock_version,
      :with_location,
      :with_translation,
      :with_semantic_version,
      base_path: '/live',
      format: 'topic'
    )

    expect(Queries::GetContentCollection.new(
      content_format: 'topic',
      fields: ['base_path'],
    ).call).to eq([
      { "base_path" => "/draft", "publication_state" => "draft"},
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
        :with_lock_version,
        :with_location,
        :with_translation,
        :with_semantic_version,
        base_path: '/a',
        format: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        :with_lock_version,
        :with_location,
        :with_translation,
        :with_semantic_version,
        base_path: '/b',
        format: 'topic',
        publishing_app: 'publisher'
      )
      FactoryGirl.create(
        :draft_content_item,
        :with_lock_version,
        :with_location,
        :with_translation,
        :with_semantic_version,
        base_path: '/c',
        format: 'topic',
        publishing_app: 'whitehall'
      )
    end

    it "returns items corresponding to the publishing_app parameter if present" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['publishing_app'],
        publishing_app: 'publisher'
      ).call).to eq([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" }
      ])
    end

    it "returns items for all apps if publishing_app is not present" do
      expect(Queries::GetContentCollection.new(
        content_format: 'topic',
        fields: ['publishing_app']
      ).call).to eq([
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "publisher", "publication_state" => "draft" },
        { "publishing_app" => "whitehall", "publication_state" => "draft" }
      ])
    end
  end
end
