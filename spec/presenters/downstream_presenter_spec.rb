require 'rails_helper'

RSpec.describe Presenters::DownstreamPresenter do
  let(:event) { double(:event, id: 123) }

  describe "V2" do
    context "for a live content item" do
      let!(:content_item) { create(:live_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      it "presents the object graph for the content store" do
        result = described_class.present(content_item, event)

        expect(result).to eq(
          content_id: content_item.content_id,
          base_path: "/vat-rates",
          analytics_identifier: "GDS01",
          description: "VAT rates for goods and services",
          details: { body: "<p>Something about VAT</p>\n" },
          format: "guide",
          document_type: "guide",
          links: Presenters::Queries::LinkSetPresenter.new(link_set).links,
          locale: "en",
          need_ids: %w(100123 100124),
          phase: "beta",
          public_updated_at: "2014-05-14T13:00:06Z",
          publishing_app: "publisher",
          redirects: [],
          rendering_app: "frontend",
          routes: [{ path: "/vat-rates", type: "exact" }],
          schema_name: "guide",
          title: "VAT rates",
          payload_version: 123,
          update_type: "minor",
        )
      end
    end

    context "for a draft content item" do
      let!(:content_item) { create(:draft_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      it "presents the object graph for the content store" do
        result = described_class.present(content_item, event)

        expect(result).to eq(
          content_id: content_item.content_id,
          base_path: "/vat-rates",
          analytics_identifier: "GDS01",
          description: "VAT rates for goods and services",
          details: { body: "<p>Something about VAT</p>\n" },
          document_type: "guide",
          format: "guide",
          links: Presenters::Queries::LinkSetPresenter.new(link_set).links,
          locale: "en",
          need_ids: %w(100123 100124),
          phase: "beta",
          public_updated_at: "2014-05-14T13:00:06Z",
          publishing_app: "publisher",
          redirects: [],
          rendering_app: "frontend",
          routes: [{ path: "/vat-rates", type: "exact" }],
          schema_name: "guide",
          title: "VAT rates",
          payload_version: 123,
          update_type: "minor",
        )
      end
    end

    describe "conditional attributes" do
      let!(:content_item) { create(:live_content_item) }
      let!(:link_set) { create(:link_set, content_id: content_item.content_id) }

      context "when the link_set is not present" do
        before { link_set.destroy }

        it "does not raise an error" do
          expect {
            described_class.present(content_item, event)
          }.to_not raise_error
        end
      end

      context "when the public_updated_at is not present" do
        let!(:content_item) { create(:gone_draft_content_item) }

        it "does not raise an error" do
          expect {
            described_class.present(content_item, event)
          }.to_not raise_error
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
