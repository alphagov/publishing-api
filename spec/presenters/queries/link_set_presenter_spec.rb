RSpec.describe Presenters::Queries::LinkSetPresenter do
  describe ".present" do
    let(:content_id) { SecureRandom.uuid }
    let(:link_set) do
      create(:link_set, content_id: content_id, stale_lock_version: 101)
    end

    subject(:result) do
      Presenters::Queries::LinkSetPresenter.present(link_set)
    end

    it "returns link set attributes as a hash" do
      expect(result.fetch(:content_id)).to eq(content_id)
    end

    it "exposes the lock_version of the link set" do
      expect(result.fetch(:version)).to eq(101)
    end
  end

  context "#links" do
    describe "returns the links as a hash, grouping them by their link_type" do
      let(:link_set) { create(:link_set) }
      let(:links) { Presenters::Queries::LinkSetPresenter.new(link_set).links }

      it "returns and empty hash when no links are present" do
        expect(links).to eq({})
      end

      it "returns a hash, grouping links by their link_type" do
        org_content_id1 = SecureRandom.uuid
        org_content_id2 = SecureRandom.uuid
        rel_content_id1 = SecureRandom.uuid

        create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id1)
        create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id2)
        create(:link, link_set: link_set, link_type: "related_links", target_content_id: rel_content_id1)

        expect(links[:organisations]).to match_array(
          [org_content_id1, org_content_id2],
        )
        expect(links[:related_links]).to match_array(
          [rel_content_id1],
        )
      end
    end
  end
end
