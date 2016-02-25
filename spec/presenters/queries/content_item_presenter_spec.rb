require 'rails_helper'

RSpec.describe Presenters::Queries::ContentItemPresenter do
  describe "present" do
    let(:content_id) { SecureRandom.uuid }
    let(:content_item) do
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
        "public_updated_at" => "2014-05-14 13:00:06",
        "details" => {
          "body" => "<p>Something about VAT</p>\n"
        },
        "routes" => [{ "path" => "/vat-rates", "type" => "exact" }],
        "redirects" => [],
        "publishing_app" => "publisher",
        "rendering_app" => "frontend",
        "need_ids" => ["100123", "100124"],
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
      let(:content_item) do
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
      let(:content_item) do
        FactoryGirl.create(
          :live_content_item,
          content_id: content_id,
          lock_version: 100,
        )
      end

      before do
        FactoryGirl.create(
          :draft_content_item,
          content_id: content_id,
          lock_version: 101,
        )
      end

      it "shows the publication state of the content item as redrafted" do
        expect(result.fetch("publication_state")).to eq("redrafted")
      end

      it "exposes the live lock_version number" do
        expect(result.fetch("live_version")).to eq(100)
      end
    end

    context "with a live lock_version only" do
      let(:content_item) do
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

      it "presents the item with matching locale" do
        result = described_class.present(french_item)
        expect(result.fetch("locale")).to eq("fr")

        result = described_class.present(english_item)
        expect(result.fetch("locale")).to eq("en")
      end

      describe "#present_many" do
        it "presents a content item for each locale" do
          content_items = ContentItem.where(content_id: content_id)

          results = described_class.present_many(content_items)
          locales = results.map { |r| r.fetch("locale") }

          expect(locales).to match_array ["fr", "en"]
        end

        context "when an array of fields is provided" do
          let(:fields) { ["title", "phase", "publication_state"] }

          it "returns the requested fields plus some additional fields" do
            content_items = ContentItem.where(content_id: content_id)

            results = described_class.present_many(content_items, fields: fields)
            expect(results.first.keys).to match_array(["title", "phase", "publication_state"])
          end
        end
      end
    end
  end
end
