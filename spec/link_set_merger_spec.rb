require 'rails_helper'

RSpec.describe LinkSetMerger do
  describe ".merge_links_into(content_id)" do
    let(:content_id) { "727ef350-81ed-4b46-9e46-ff3dc83303d5" }
    let!(:content_item) {
      FactoryGirl.create(:draft_content_item, content_id: content_id)
    }

    context "when a link set exists" do
      let!(:link_set) {
        FactoryGirl.create(:link_set, content_id: content_id)
      }

      it "returns a hash representing the merged content item and link set" do
        merged_result = subject.merge_links_into(content_item)

        DraftContentItem::TOP_LEVEL_FIELDS.each do |field|
          expect(merged_result[field]).to eq(content_item.public_send(field))
        end

        expect(merged_result[:links]).to eq(link_set.links)
      end
    end

    context "when a link set does not exist" do
      it "returns a hash representing the content item" do
        merged_result = subject.merge_links_into(content_item)

        DraftContentItem::TOP_LEVEL_FIELDS.each do |field|
          expect(merged_result[field]).to eq(content_item.public_send(field))
        end
      end
    end
  end
end
