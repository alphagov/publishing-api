require 'rails_helper'

RSpec.describe Presenters::Queries::ContentItemPresenter do
  describe "present" do
    let(:content_id) { SecureRandom.uuid }
    let(:content_item) { FactoryGirl.create(:draft_content_item, content_id: content_id) }
    let!(:version) { FactoryGirl.create(:version, target: content_item, number: 101) }
    let(:result) { Presenters::Queries::ContentItemPresenter.present(content_item) }

    it "presents content item attributes as a hash" do
      expected = {
        content_id: content_id,
        locale: "en",
        base_path: "/vat-rates",
        title: "VAT rates",
        format: "guide",
        public_updated_at: DateTime.parse("2014-05-14 13:00:06.000000000 +0000").in_time_zone,
        details: {
          body: "<p>Something about VAT</p>\n"
        },
        routes: [{path: "/vat-rates", type: "exact"}],
        redirects: [],
        publishing_app: "publisher",
        rendering_app: "frontend",
        need_ids: ["100123", "100124"],
        update_type: "minor",
        phase: "beta",
        analytics_identifier: "GDS01",
        description: "VAT rates for goods and services",
        publication_state: "draft",
        version: 101
      }
      expect(result).to eq(expected)
    end

    it "exposes the version number of the content item" do
      expect(result.fetch(:version)).to eq(101)
    end

    context "with no published version" do
      it "shows the publication state of the content item as draft" do
        expect(result.fetch(:publication_state)).to eq("draft")
      end

      it "does not include live_version" do
        expect(result).not_to have_key(:live_version)
      end
    end

    context "with a published version and no subsequent draft" do
      let(:live_content_item) { FactoryGirl.create(:live_content_item, content_id: content_id, draft_content_item: content_item) }

      before do
        FactoryGirl.create(:version, target: live_content_item, number: 101)
      end

      it "shows the publication state of the content item as live" do
        expect(result.fetch(:publication_state)).to eq("live")
      end

      it "exposes the live version number" do
        expect(result.fetch(:live_version)).to eq(101)
      end
    end

    context "with a published version and a subsequent draft" do
      let(:live_content_item) { FactoryGirl.create(:live_content_item, content_id: content_id, draft_content_item: content_item) }

      before do
        FactoryGirl.create(:version, target: live_content_item, number: 100)
      end

      it "shows the publication state of the content item as redrafted" do
        expect(result.fetch(:publication_state)).to eq("redrafted")
      end

      it "exposes the live version number" do
        expect(result.fetch(:live_version)).to eq(100)
      end
    end

    context "with a live version only" do
      let(:content_item) { FactoryGirl.create(:live_content_item, content_id: content_id ) }
      let!(:version) { FactoryGirl.create(:version, target: content_item, number: 100) }
      let(:result) { Presenters::Queries::ContentItemPresenter.new(content_item, nil, version).present }

      it "shows the publication state of the content item as live" do
        expect(result.fetch(:publication_state)).to eq("live")
      end
    end
  end
end
