require 'rails_helper'

RSpec.describe Presenters::DownstreamPresenter do
  let(:event) { double(:event, id: 123) }
  let(:fallback_order) { [] }

  subject(:result) { described_class.present(content_item, event, fallback_order: fallback_order) }

  describe "V2" do
    let(:expected) {
      {
        content_id: content_item.content_id,
        base_path: "/vat-rates",
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        details: { body: "<p>Something about VAT</p>\n" },
        format: "guide",
        document_type: "guide",
        links: {},
        expanded_links: {},
        locale: "en",
        need_ids: %w(100123 100124),
        phase: "beta",
        first_published_at: "2014-01-02T03:04:05Z",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "publisher",
        redirects: [],
        rendering_app: "frontend",
        routes: [{ path: "/vat-rates", type: "exact" }],
        schema_name: "guide",
        title: "VAT rates",
        payload_version: 123,
        update_type: "minor"
      }
    }

    context "for a live content item" do
      let(:content_item) { create(:live_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      it "presents the object graph for the content store" do
        expect(result).to eq(expected)
      end
    end

    context "for a draft content item" do
      let(:content_item) { create(:draft_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      it "presents the object graph for the content store" do
        expect(result).to eq(expected)
      end
    end

    context "for a content item with dependencies" do
      let(:a) { FactoryGirl.create(:content_item, base_path: "/a") }
      let(:b) { FactoryGirl.create(:content_item, base_path: "/b") }

      before do
        FactoryGirl.create(:link_set, content_id: a.content_id, links: [
          FactoryGirl.create(:link, link_type: "related", target_content_id: b.content_id)
        ])
      end

      it "expands the links for the content item" do
        result = described_class.present(a, event, fallback_order: [:draft])

        expect(result[:expanded_links]).to eq(related: [{
          content_id: b.content_id,
          base_path: "/b",
          title: "VAT rates",
          description: "VAT rates for goods and services",
          locale: "en",
          api_url: "http://www.dev.gov.uk/api/content/b",
          web_url: "http://www.dev.gov.uk/b",
          analytics_identifier: "GDS01",
          expanded_links: {},
        }])
      end
    end

    describe "conditional attributes" do
      let!(:content_item) { create(:live_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      context "when the link_set is not present" do
        before { link_set.destroy }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end

      context "when the public_updated_at is not present" do
        let(:content_item) { create(:gone_draft_content_item) }

        it "does not raise an error" do
          expect { result }.not_to raise_error
        end
      end
    end
  end

  describe described_class::V1 do
    let(:attributes) do
      {
        content_id: "content_id",
        access_limited: "access_limited",
        update_type: "update_type",
      }
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    it "presents all attributes by default" do
      result = described_class.present(attributes, event)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        update_type: "update_type",
        payload_version: 123,
      )
    end

    it "can optionally remove the update_type attribute" do
      result = described_class.present(attributes, event, update_type: false)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        payload_version: 123,
      )
    end

    it "can optionally remove the payload_version attribute" do
      result = described_class.present(attributes, event, payload_version: false)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        update_type: "update_type",
      )
    end
  end
end
