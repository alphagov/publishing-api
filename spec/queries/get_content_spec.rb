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
    let(:incorrect_version) { 2 }
    let(:incorrect_locale) { "fr" }

    before do
      FactoryGirl.create(:content_item,
        content_id: content_id,
        base_path: "/vat-rates",
        user_facing_version: 1,
        locale: "en",
      )
    end

    it "presents the content item" do
      result = subject.call(content_id)

      expect(result).to include(
        "content_id" => content_id,
        "base_path" => "/vat-rates",
        "title" => "VAT rates",
        "document_type" => "guide",
        "schema_name" => "guide",
        "locale" => "en",
        "lock_version" => 1,
        "publication_state" => "draft",
        "publishing_app" => "publisher",
        "rendering_app" => "frontend",
      )
    end

    context "when a content item for the requested version does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, version: incorrect_version)
        }.to raise_error(CommandError, /version: #{incorrect_version} for content item/)
      end
    end

    context "when a content item for the requested locale does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, incorrect_locale)
        }.to raise_error(CommandError, /locale: #{incorrect_locale} for content item/)
      end
    end

    context "when a content item for the requested version and locale does not exist" do
      it "raises a command error" do
        expect {
          subject.call(content_id, incorrect_locale, version: incorrect_version)
        }.to raise_error(CommandError, /locale: #{incorrect_locale} and version: #{incorrect_version}/)
      end
    end
  end

  context "when a draft and a live content item exists for the content_id" do
    before do
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        title: "Draft Title",
        user_facing_version: 2,
      )

      FactoryGirl.create(:live_content_item,
        content_id: content_id,
        title: "Live Title",
        user_facing_version: 1,
      )
    end

    it "presents the draft content item" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Draft Title")
    end
  end

  context "when content items exist in non-draft, non-live states" do
    before do
      FactoryGirl.create(:content_item,
        content_id: content_id,
        user_facing_version: 1,
        title: "Published Title",
        state: "published",
      )

      FactoryGirl.create(:superseded_content_item,
        content_id: content_id,
        user_facing_version: 2,
        title: "Submitted Title",
      )
    end

    it "includes these content items" do
      result = subject.call(content_id)
      expect(result.fetch("title")).to eq("Submitted Title")
    end
  end

  context "when content items exist in multiple locales" do
    before do
      FactoryGirl.create(:content_item,
        content_id: content_id,
        user_facing_version: 2,
        title: "French Title",
        locale: "fr",
      )

      FactoryGirl.create(:content_item,
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

  describe "requesting specific versions" do
    before do
      FactoryGirl.create(:superseded_content_item,
        content_id: content_id,
        user_facing_version: 1,
      )

      FactoryGirl.create(:live_content_item,
        content_id: content_id,
        user_facing_version: 2,
      )
    end

    it "returns specific versions if provided" do
      result = subject.call(content_id, version: 1)
      expect(result.fetch("publication_state")).to eq("superseded")

      result = subject.call(content_id, version: 2)
      expect(result.fetch("publication_state")).to eq("published")
    end

    it "returns the most recent if version isn't given" do
      result = subject.call(content_id)
      expect(result.fetch("publication_state")).to eq("published")
    end
  end
end
