require 'rails_helper'

RSpec.describe Presenters::Queries::ContentItemPresenter do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  describe "present" do
    let!(:content_item) do
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        base_path: base_path
      )
    end

    let(:result) { described_class.present(content_item) }

    around do |example|
      Timecop.freeze(Date.new(2016, 1, 1)) do
        example.run
      end
    end

    it "presents content item attributes as a hash" do
      expect(result).to eq(
        "content_id" => content_id,
        "locale" => "en",
        "base_path" => base_path,
        "title" => "VAT rates",
        "internal_name" => "VAT rates",
        "document_type" => "guide",
        "schema_name" => "guide",
        "public_updated_at" => "2014-05-14T13:00:06Z",
        "last_edited_at" => "2014-05-14T13:00:06Z",
        "first_published_at" => "2014-01-02T03:04:05Z",
        "details" => { "body" => "<p>Something about VAT</p>\n" },
        "routes" => [{ "path" => base_path, "type" => "exact" }],
        "redirects" => [],
        "publishing_app" => "publisher",
        "rendering_app" => "frontend",
        "need_ids" => %w(100123 100124),
        "update_type" => "minor",
        "phase" => "beta",
        "analytics_identifier" => "GDS01",
        "description" => "VAT rates for goods and services",
        "publication_state" => "draft",
        "user_facing_version" => 1,
        "lock_version" => 1,
        "updated_at" => "2016-01-01 00:00:00",
      )
    end

    context "for a draft content item" do
      it "has a publication state of draft" do
        expect(result.fetch("publication_state")).to eq("draft")
      end

      context "that has a user facing version greater than 1" do
        before do
          version = UserFacingVersion.last
          version.number = 2
          version.save!
        end

        it "has a publication state of redrafted" do
          expect(result.fetch("publication_state")).to eq("redrafted")
        end
      end
    end

    context "for a published content item" do
      before do
        State.find_by!(content_item: content_item).update!(name: "published")
      end

      it "has a publication state of live" do
        expect(result.fetch("publication_state")).to eq("live")
      end
    end

    context "when the content item exists in multiple locales" do
      let!(:french_item) do
        FactoryGirl.create(:content_item, content_id: content_id, locale: "fr")
      end

      it "presents the item with matching locale" do
        result = described_class.present(french_item)
        expect(result.fetch("locale")).to eq("fr")

        result = described_class.present(content_item)
        expect(result.fetch("locale")).to eq("en")
      end
    end
  end

  describe "#present_many" do
    let!(:content_item) do
      FactoryGirl.create(:content_item,
        content_id: content_id,
      )
    end

    context "when an array of fields is provided" do
      let(:fields) { %w(title phase publication_state) }

      it "returns the requested fields" do
        content_items = ContentItem.where(content_id: content_id)

        results = described_class.present_many(content_items, fields: fields)
        expect(results.first.keys).to match_array(%w(title phase publication_state))
      end
    end

    context "when internal_name is requested" do
      let(:fields) { %w(internal_name) }

      context "and an internal_name is present" do
        before do
          details = content_item.details
          details["internal_name"] = "An internal name"

          content_item.update_attributes(
            details: details,
          )
        end

        it "returns the internal_name" do
          content_items = ContentItem.where(content_id: content_id)

          results = described_class.present_many(content_items, fields: fields)
          expect(results.first["internal_name"]).to eq("An internal name")
        end
      end

      context "but an internal_name is not present" do
        before do
          details = content_item.details
          details.delete(:internal_name)

          content_item.update_attributes(
            details: details,
            title: "A normal title",
          )
        end

        it "falls back to the title" do
          content_items = ContentItem.where(content_id: content_id)

          results = described_class.present_many(content_items, fields: fields)
          expect(results.first["internal_name"]).to eq("A normal title")
        end
      end
    end

    context "when the content item exists in multiple locales" do
      let!(:french_item) do
        FactoryGirl.create(:content_item, content_id: content_id, locale: "fr")
      end

      it "presents a content item for each locale" do
        content_items = ContentItem.where(content_id: content_id)

        results = described_class.present_many(content_items)
        locales = results.map { |r| r.fetch("locale") }

        expect(locales).to match_array(%w(fr en))
      end
    end
  end
end
