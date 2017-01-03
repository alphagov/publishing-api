require 'rails_helper'

RSpec.describe Presenters::Queries::LinkSetPresenter do
  describe ".present" do
    let(:content_id) { SecureRandom.uuid }
    let(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }

    before do
      FactoryGirl.create(:lock_version, target: link_set, number: 101)
      @result = Presenters::Queries::LinkSetPresenter.present(link_set)
    end

    it "returns link set attributes as a hash" do
      expect(@result.fetch(:content_id)).to eq(content_id)
    end

    it "exposes the lock_version of the link set" do
      expect(@result.fetch(:version)).to eq(101)
    end
  end

  context "#links" do
    describe "returns the links as a hash, grouping them by their link_type" do
      let(:link_set) { FactoryGirl.create(:link_set) }
      let(:links) { Presenters::Queries::LinkSetPresenter.new(link_set).links }

      it "returns and empty hash when no links are present" do
        expect(links).to eq({})
      end

      it "returns a hash, grouping links by their link_type" do
        org_content_id_1 = SecureRandom.uuid
        org_content_id_2 = SecureRandom.uuid
        rel_content_id_1 = SecureRandom.uuid

        FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id_1)
        FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id_2)
        FactoryGirl.create(:link, link_set: link_set, link_type: "related_links", target_content_id: rel_content_id_1)

        expect(links[:organisations]).to match_array(
          [org_content_id_1, org_content_id_2]
        )
        expect(links[:related_links]).to match_array(
          [rel_content_id_1]
        )
      end
    end
  end
end
