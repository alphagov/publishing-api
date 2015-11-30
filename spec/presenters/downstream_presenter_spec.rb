require 'rails_helper'

RSpec.describe Presenters::DownstreamPresenter do
  around do |example|
    Timecop.freeze { example.run }
  end

  context "for a live content item" do
    let!(:content_item) { FactoryGirl.create(:live_content_item) }
    let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_item.content_id) }

    it "presents the object graph for the content store (excludes access_limited)" do
      result = described_class.present(content_item)

      expect(result).to eq(
        content_id: content_item.content_id,
        base_path: "/vat-rates",
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        details: { body: "<p>Something about VAT</p>\n" },
        format: "guide",
        links: Presenters::Queries::LinkSetPresenter.new(link_set).links,
        locale: "en",
        need_ids: ["100123", "100124"],
        phase: "beta",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "mainstream_publisher",
        redirects: [],
        rendering_app: "mainstream_frontend",
        routes: [{ path: "/vat-rates", type: "exact" }],
        title: "VAT rates",
        transmitted_at: DateTime.now.to_s(:nanoseconds),
        update_type: "minor",
      )
    end
  end

  context "for a draft content item" do
    let!(:content_item) { FactoryGirl.create(:draft_content_item) }
    let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_item.content_id) }

    it "presents the object graph for the content store" do
      result = described_class.present(content_item)

      expect(result).to eq(
        content_id: content_item.content_id,
        base_path: "/vat-rates",
        access_limited: nil,
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        details: { body: "<p>Something about VAT</p>\n" },
        format: "guide",
        links: Presenters::Queries::LinkSetPresenter.new(link_set).links,
        locale: "en",
        need_ids: ["100123", "100124"],
        phase: "beta",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "mainstream_publisher",
        redirects: [],
        rendering_app: "mainstream_frontend",
        routes: [{ path: "/vat-rates", type: "exact" }],
        title: "VAT rates",
        transmitted_at: DateTime.now.to_s(:nanoseconds),
        update_type: "minor",
      )
    end
  end

  describe "conditional attributes" do
    let!(:content_item) { FactoryGirl.create(:live_content_item) }
    let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_item.content_id) }

    context "when the link_set is not present" do
      before { link_set.destroy }

      it "does not raise an error" do
        expect {
          described_class.present(content_item)
        }.to_not raise_error
      end
    end

    context "when the public_updated_at is not present" do
      let!(:content_item) { FactoryGirl.create(:gone_draft_content_item, public_updated_at: nil) }

      it "does not raise an error" do
        expect {
          described_class.present(content_item)
        }.to_not raise_error
      end
    end
  end

  describe "presented transmitted_at datetime format" do
    it "returns a string formatted as nanoseconds" do
      datetime = DateTime.now
      nanoseconds = datetime.to_s(:nanoseconds)

      expect(nanoseconds).to eq(datetime.strftime("%s%9N"))
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

    it "presents all attributes by default and mixes in transmitted_at" do
      result = described_class.present(attributes)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        update_type: "update_type",
        transmitted_at: DateTime.now.to_s(:nanoseconds),
      )
    end

    it "can optionally remove the access_limited attribute" do
      result = described_class.present(attributes, access_limited: false)

      expect(result).to eq(
        content_id: "content_id",
        update_type: "update_type",
        transmitted_at: DateTime.now.to_s(:nanoseconds),
      )
    end

    it "can optionally remove the update_type attribute" do
      result = described_class.present(attributes, update_type: false)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        transmitted_at: DateTime.now.to_s(:nanoseconds),
      )
    end

    it "can optionally omit the transmitted_at" do
      result = described_class.present(attributes, transmitted_at: false)

      expect(result).to eq(
        content_id: "content_id",
        access_limited: "access_limited",
        update_type: "update_type",
      )
    end
  end
end
