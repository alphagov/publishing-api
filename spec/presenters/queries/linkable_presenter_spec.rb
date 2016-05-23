require 'rails_helper'

RSpec.describe Presenters::Queries::LinkablePresenter do
  describe ".present" do
    let!(:linkable) {
      FactoryGirl.create(:linkable)
    }

    it "loads some fields from the Linkable" do
      output = described_class.present(linkable)

      expect(output[:base_path]).to eq(linkable.base_path)
    end

    it "loads some fields from the ContentItem" do
      output = described_class.present(linkable)

      expect(output[:title]).to eq(linkable.content_item.title)
      expect(output[:content_id]).to eq(linkable.content_item.content_id)
    end

    it "defaults the internal name to the title if not present" do
      linkable.content_item.update_attributes(details: { internal_name: "An internal name" })
      output = described_class.present(linkable)
      expect(output[:internal_name]).to eq("An internal name")

      linkable.content_item.update_attributes(details: {})
      linkable.content_item.update_attributes(title: "A title")
      output = described_class.present(linkable)
      expect(output[:internal_name]).to eq("A title")
    end

    it "shows the publication_state as 'live' if published" do
      linkable.update_attributes(state: "published")
      output = described_class.present(linkable)
      expect(output[:publication_state]).to eq("live")

      linkable.update_attributes(state: "draft")
      output = described_class.present(linkable)
      expect(output[:publication_state]).to eq("draft")
    end
  end
end
