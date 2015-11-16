require 'rails_helper'

RSpec.describe LinkSet do
  context "#hashed_links" do
    describe "returns links as a hash, grouping them by their link_type" do
      let(:link_set) { FactoryGirl.create(:link_set) }
      it "returns and empty hash when no links are present" do
        expect(link_set.hashed_links).to eq({})
      end

      it "returns a hash, grouping links by their link_type" do
        org_content_id_1 = SecureRandom.uuid
        org_content_id_2 = SecureRandom.uuid
        rel_content_id_1 = SecureRandom.uuid

        org_link1 = FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id_1)
        org_link2 = FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: org_content_id_2)
        related_link = FactoryGirl.create(:link, link_set: link_set, link_type: "related_links", target_content_id: rel_content_id_1)

        expect(link_set.hashed_links).to eq({
          :organisations => [ org_content_id_1, org_content_id_2 ],
          :related_links => [ rel_content_id_1 ]
        })
      end
    end
  end
end
