require 'rails_helper'

RSpec.describe SubstitutionHelper do
  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { '/vat-rates' }
  let(:payload) {
    FactoryGirl.build(:live_content_item,
        content_id: content_id,
        title: 'The title',
        base_path: base_path
      )
  }

  context "when there's an existing gone on the path already" do
    before do
      create(:gone_live_content_item, base_path: base_path)
    end

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when there's an existing redirect on the path already" do
    before do
      create(:redirect_live_content_item, base_path: base_path)
    end

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when there's an existing unpublishing on the path already" do
    before do
      create(:live_content_item, base_path: base_path, format: "unpublishing")
    end

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when a gone item wants to replace a content item" do
    before do
      create(:live_content_item, base_path: base_path)
    end

    let(:payload) {
      FactoryGirl.build(:gone_live_content_item,
        content_id: content_id,
        base_path: base_path
      )
    }

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when a redirect item wants to replace a content item" do
    before do
      create(:live_content_item, base_path: base_path)
    end

    let(:payload) {
      FactoryGirl.build(:redirect_live_content_item,
        content_id: content_id,
        base_path: base_path
      )
    }

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when an unpublishing item wants to replace a content item" do
    before do
      create(:live_content_item, base_path: base_path)
    end

    let(:payload) {
      FactoryGirl.build(:live_content_item,
        format: "unpublishing",
        content_id: content_id,
        base_path: base_path
      )
    }

    it "removes the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(false)
    end
  end

  context "when a content item wants to replace a content item" do
    before do
      create(:live_content_item, base_path: base_path)
    end

    it "does not remove the existing content" do
      described_class.clear_live!(payload)
      expect(LiveContentItem.exists?(base_path: base_path)).to eq(true)
    end
  end
end
