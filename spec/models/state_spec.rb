require "rails_helper"

RSpec.describe State do
  describe "validations" do
    subject { FactoryGirl.build(:state) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    context "when another content item has identical supporting objects" do
      before do
        FactoryGirl.create(:content_item, state: "published")
      end

      let(:content_item) do
        FactoryGirl.create(:content_item, state: "draft")
      end

      subject { FactoryGirl.build(:state, content_item: content_item, name: "published") }

      it "is invalid" do
        expect(subject).to be_invalid

        error = subject.errors[:content_item].first
        expect(error).to match(/conflicts with/)
      end
    end
  end

  describe ".filter" do
    let!(:draft_item) { FactoryGirl.create(:draft_content_item, title: "Draft Title") }
    let!(:published_item) { FactoryGirl.create(:live_content_item, title: "Published Title") }

    it "filters a content item scope by state name" do
      draft_items = described_class.filter(ContentItem.all, name: "draft")
      expect(draft_items.pluck(:title)).to eq(["Draft Title"])

      published_items = described_class.filter(ContentItem.all, name: "published")
      expect(published_items.pluck(:title)).to eq(["Published Title"])
    end
  end

  describe ".supersede" do
    let(:draft_item) { FactoryGirl.create(:draft_content_item, title: "Draft Title") }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'superseded'" do
      expect {
        described_class.supersede(draft_item)
      }.to change { draft_state.reload.name }.to("superseded")
    end
  end

  describe ".publish" do
    let(:draft_item) { FactoryGirl.create(:draft_content_item, title: "Draft Title") }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'published'" do
      expect {
        described_class.publish(draft_item)
      }.to change { draft_state.reload.name }.to("published")
    end
  end

  describe ".withdraw" do
    let(:draft_item) { FactoryGirl.create(:draft_content_item, title: "Draft Title") }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'withdrawn'" do
      expect {
        described_class.withdraw(draft_item)
      }.to change { draft_state.reload.name }.to("withdrawn")
    end
  end
end
