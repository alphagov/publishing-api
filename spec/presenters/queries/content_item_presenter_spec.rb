require 'rails_helper'

RSpec.describe Presenters::Queries::ContentItemPresenter do
  let(:content_id) { SecureRandom.uuid }

  describe "present" do
    let!(:content_item) do
      FactoryGirl.create(
        :draft_content_item,
        content_id: content_id,
        lock_version: 101,
      )
    end
    let(:result) { Presenters::Queries::ContentItemPresenter.present(content_item) }

    it "presents content item attributes as a hash" do
      expected = {
        "content_id" => content_id,
        "locale" => "en",
        "base_path" => "/vat-rates",
        "title" => "VAT rates",
        "format" => "guide",
        "document_type" => "guide",
        "schema_name" => "guide",
        "public_updated_at" => "2014-05-14 13:00:06",
        "details" => {
          "body" => "<p>Something about VAT</p>\n"
        },
        "routes" => [{ "path" => "/vat-rates", "type" => "exact" }],
        "redirects" => [],
        "publishing_app" => "publisher",
        "rendering_app" => "frontend",
        "need_ids" => %w(100123 100124),
        "update_type" => "minor",
        "phase" => "beta",
        "analytics_identifier" => "GDS01",
        "description" => "VAT rates for goods and services",
        "publication_state" => "draft",
        "lock_version" => 101
      }
      expect(result).to eq(expected)
    end

    context "with no published lock_version" do
      it "shows the publication state of the content item as draft" do
        expect(result.fetch("publication_state")).to eq("draft")
      end

      it "does not include live_version" do
        expect(result).not_to have_key(:live_version)
      end
    end

    context "with a published lock_version and no subsequent draft" do
      let!(:content_item) do
        FactoryGirl.create(
          :live_content_item,
          content_id: content_id,
          lock_version: 101,
        )
      end

      it "shows the publication state of the content item as live" do
        expect(result.fetch("publication_state")).to eq("live")
      end

      it "exposes the live lock_version number" do
        expect(result.fetch("live_version")).to eq(101)
      end
    end

    context "with a published lock_version and a subsequent draft" do
      let!(:content_item) do
        FactoryGirl.create(
          :live_content_item,
          content_id: content_id,
          lock_version: 100,
          title: "Live copy",
        )
      end

      before do
        FactoryGirl.create(
          :draft_content_item,
          content_id: content_id,
          lock_version: 101,
          title: "Draft copy",
        )
      end

      it "shows the publication state of the content item as redrafted" do
        expect(result.fetch("publication_state")).to eq("redrafted")
      end

      it "exposes the live lock_version number" do
        expect(result.fetch("live_version")).to eq(100)
      end

      it "returns the newest copy" do
        expect(result.fetch("title")).to eq("Draft copy")
      end
    end

    context "with a live lock_version only" do
      let!(:content_item) do
        FactoryGirl.create(
          :live_content_item,
          content_id: content_id,
          lock_version: 100,
        )
      end

      it "shows the publication state of the content item as live" do
        expect(result.fetch("publication_state")).to eq("live")
      end
    end
  end

  context "when the content item exists in multiple locales" do
    let!(:french_item) do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        locale: "fr"
      )
    end

    let!(:english_item) do
      FactoryGirl.create(
        :content_item,
        content_id: content_id,
        locale: "en"
      )
    end

    describe "#present" do
      it "presents the item with matching locale" do
        result = described_class.present(french_item)
        expect(result.fetch("locale")).to eq("fr")

        result = described_class.present(english_item)
        expect(result.fetch("locale")).to eq("en")
      end
    end

    describe "#present_many" do
      it "presents a content item for each locale" do
        content_items = ContentItem.where(content_id: content_id)

        results = described_class.present_many(content_items)
        locales = results.map { |r| r.fetch("locale") }

        expect(locales).to match_array(%w(fr en))
      end
    end
  end

  describe "#present_many" do
    let!(:content_item) do
      FactoryGirl.create(
        :content_item,
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
          details[:internal_name] = "An internal name"

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
  end
end
