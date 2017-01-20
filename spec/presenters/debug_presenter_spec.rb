require "rails_helper"

RSpec.describe Presenters::DebugPresenter do
  let(:document) { FactoryGirl.create(:document) }

  let!(:content_item) do
    FactoryGirl.create(:draft_content_item,
                       document: document,
                       user_facing_version: 3)
  end

  let!(:link_set) { FactoryGirl.create(:link_set, content_id: document.content_id) }

  subject do
    described_class.new(document.content_id)
  end

  describe ".content_items" do
    it "has one entry" do
      expect(subject.content_items.length).to eq(1)
    end
  end

  describe ".user_facing_versions" do
    it "has one entry" do
      expect(subject.user_facing_versions.length).to eq(1)
    end

    it "matches" do
      expect(subject.user_facing_versions[0]).to eq(3)
    end
  end

  describe ".latest_content_items" do
    it "has one entry" do
      expect(subject.latest_content_items.length).to eq(1)
    end
  end

  describe ".latest_state_with_locale" do
    it "matches" do
      expect(subject.latest_state_with_locale[0]).to eq(["en", "draft"])
    end
  end

  describe ".web_content_item" do
    it "matches" do
      expect(subject.web_content_item.base_path).to match("/vat-rates-")
    end
  end

  describe ".title" do
    it "matches" do
      expect(subject.title).to eq("VAT rates")
    end
  end

  describe ".web_url" do
    it "matches" do
      expect(subject.web_url).to match("/vat-rates-")
    end
  end

  describe ".api_url" do
    it "matches" do
      expect(subject.api_url).to match("api/content/vat-rates-")
    end
  end

  describe ".link_set" do
    it "is not nil" do
      expect(subject.link_set).to_not be_nil
    end
  end

  describe ".expanded_links" do
    it "has four entries" do
      expect(subject.expanded_links.length).to eq(3)
    end
  end

  describe ".states" do
    it "has four entries" do
      expect(subject.states.length).to eq(2)
    end
  end
end
