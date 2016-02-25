require "rails_helper"

RSpec.describe Queries::GetContent do
  let(:content_id) { SecureRandom.uuid }

  context "when no content item exists for the content_id" do
    it "raises a command error" do
      expect {
        subject.call(content_id)
      }.to raise_error(CommandError, /with content_id: #{content_id}/)
    end
  end

  context "when a content item exists for the content_id" do
    before do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
      )
    end

    it "presents the content item" do
      result = subject.call(content_id)

      expect(result).to include(
        "content_id" => content_id,
        "base_path" => "/vat-rates",
        "title" => "VAT rates",
        "format" => "guide",
        "locale" => "en",
        "lock_version" => 1,
        "publication_state" => "draft",
        "publishing_app" => "publisher",
        "rendering_app" => "frontend",
      )
    end
  end

  context "when a draft and a live content item exists for the content_id" do
    before do
      FactoryGirl.create(
        :draft_content_item,
        content_id: content_id,
        title: "Draft Title",
      )

      FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
        title: "Live Title",
      )
    end

    it "presents the draft content item" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Draft Title")
    end
  end

  context "when content items exist in non-draft, non-live states" do
    before do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        user_facing_version: 2,
        title: "Superseded Title",
        state: "superseded",
      )

      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        user_facing_version: 1,
        title: "Published Title",
        state: "published",
      )
    end

    it "excludes content items that aren't in draft or published states" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Published Title")
    end
  end

  context "when content items exist in multiple locales" do
    before do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        user_facing_version: 2,
        title: "French Title",
        locale: "fr",
      )

      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        user_facing_version: 1,
        title: "English Title",
        locale: "en",
      )
    end

    it "returns the english content item by default" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("English Title")
    end

    it "filters content items by the specified locale" do
      result = subject.call(content_id, "fr")
      expect(result.fetch("title")).to eq("French Title")
    end
  end
end
