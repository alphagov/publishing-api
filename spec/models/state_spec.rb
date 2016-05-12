require "rails_helper"

RSpec.describe State do
  describe "validations" do
    subject { build(:state) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    context "when another content item has identical supporting objects" do
      before do
        create(:content_item, state: "published")
      end

      let(:content_item) do
        create(:content_item, state: "draft")
      end

      subject { build(:state, content_item: content_item, name: "published") }

      it "is invalid" do
        expect(subject).to be_invalid

        error = subject.errors[:content_item].first
        expect(error).to match(/conflicts with/)
      end
    end
  end

  describe ".filter" do
    let!(:draft_item) { create(:draft_content_item, title: "Draft Title") }
    let!(:published_item) { create(:live_content_item, title: "Published Title") }

    it "filters a content item scope by state name" do
      draft_items = described_class.filter(ContentItem.all, name: "draft")
      expect(draft_items.pluck(:title)).to eq(["Draft Title"])

      published_items = described_class.filter(ContentItem.all, name: "published")
      expect(published_items.pluck(:title)).to eq(["Published Title"])
    end
  end

  describe ".supersede" do
    let(:draft_item) { create(:draft_content_item) }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'superseded'" do
      expect {
        described_class.supersede(draft_item)
      }.to change { draft_state.reload.name }.to("superseded")
    end
  end

  describe ".publish" do
    let(:draft_item) { create(:draft_content_item) }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'published'" do
      expect {
        described_class.publish(draft_item)
      }.to change { draft_state.reload.name }.to("published")
    end
  end

  describe ".unpublish" do
    let(:live_item) { create(:live_content_item) }
    let(:live_state) { State.find_by!(content_item: live_item) }

    it "changes the state name to 'unpublished'" do
      expect {
        described_class.unpublish(live_item, type: "gone")
      }.to change { live_state.reload.name }.to("unpublished")
    end

    it "creates an unpublishing" do
      expect {
        described_class.unpublish(live_item,
          type: "gone",
          explanation: "A test explanation",
          alternative_path: "/some-path",
        )
      }.to change(Unpublishing, :count).by(1)

      unpublishing = Unpublishing.last

      expect(unpublishing.content_item).to eq(live_item)
      expect(unpublishing.type).to eq("gone")
      expect(unpublishing.explanation).to eq("A test explanation")
      expect(unpublishing.alternative_path).to eq("/some-path")
    end
  end

  describe ".substitute" do
    let(:live_item) { create(:live_content_item) }
    let(:live_state) { State.find_by!(content_item: live_item) }

    it "changes the state name to 'unpublished'" do
      expect {
        described_class.substitute(live_item)
      }.to change { live_state.reload.name }.to("unpublished")
    end

    it "creates a 'substitute' unpublishing" do
      expect {
        described_class.substitute(live_item)
      }.to change(Unpublishing, :count).by(1)

      unpublishing = Unpublishing.last

      expect(unpublishing.content_item).to eq(live_item)
      expect(unpublishing.type).to eq("substitute")
      expect(unpublishing.explanation).to eq(
        "Automatically unpublished to make way for another content item"
      )
    end
  end
end
