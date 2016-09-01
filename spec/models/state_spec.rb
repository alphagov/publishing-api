require "rails_helper"

RSpec.describe State do
  describe "validations" do
    subject { FactoryGirl.build(:state) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    context "when another content item has the same base path" do
      let(:base_path) { "/vat-rates" }
      let!(:content_item) do
        FactoryGirl.create(:content_item,
          state: "draft",
          base_path: base_path,
        )
      end

      subject { FactoryGirl.build(:state, content_item: content_item, name: state) }

      before do
        FactoryGirl.create(
          :content_item,
          state: "published",
          base_path: base_path,
        )
      end

      %w(published unpublished).each do |state_name|
        context "when state is #{state_name}" do
          let(:state) { state_name }
          it { is_expected.to be_invalid }
        end
      end

      %w(draft superseded).each do |state_name|
        context "when state is #{state_name}" do
          let(:state) { "superseded" }
          it { is_expected.to be_valid }
        end
      end
    end

    context "when the state conflicts with another instance of this content item" do
      let(:content_item) do
        FactoryGirl.create(
          :content_item,
          state: "superseded",
          user_facing_version: 2,
        )
      end
      subject { FactoryGirl.build(:state, content_item: content_item, name: state) }
      before do
        FactoryGirl.create(
          :content_item,
          content_id: content_item.content_id,
          state: existing_state,
          user_facing_version: 1,
        )
      end

      {
        "draft" => { "draft" => false, "published" => true, "unpublished" => true, "superseded" => true },
        "published" => { "draft" => true, "published" => false, "unpublished" => false, "superseded" => true },
        "unpublished" => { "draft" => true, "published" => false, "unpublished" => false, "superseded" => true },
        "superseded" => { "draft" => true, "published" => true, "unpublished" => true, "superseded" => true },
      }.each do |existing_state_name, possibilities|
        context "when existing state is #{existing_state_name}" do
          let(:existing_state) { existing_state_name }
          possibilities.each do |state_name, should_be_valid|
            context "when state is #{state_name}" do
              let(:state) { state_name }
              if should_be_valid
                it { is_expected.to be_valid }
              else
                it { is_expected.to be_invalid }
              end
            end
          end
        end
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
    let(:draft_item) { FactoryGirl.create(:draft_content_item) }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'superseded'" do
      expect {
        described_class.supersede(draft_item)
      }.to change { draft_state.reload.name }.to("superseded")
    end
  end

  describe ".publish" do
    let(:draft_item) { FactoryGirl.create(:draft_content_item) }
    let(:draft_state) { State.find_by!(content_item: draft_item) }

    it "changes the state name to 'published'" do
      expect {
        described_class.publish(draft_item)
      }.to change { draft_state.reload.name }.to("published")
    end
  end

  describe ".unpublish" do
    let(:live_item) { FactoryGirl.create(:live_content_item) }
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

    it "updates an existing unpublishing" do
      unpublishing = nil
      expect {
        unpublishing = described_class.unpublish(live_item,
                                  type: "gone",
                                  explanation: "A test explanation",
                                  alternative_path: "/some-path",
        )
      }.to change(Unpublishing, :count).by(1)

      last_unpublishing = Unpublishing.last
      expect(unpublishing).to eq(last_unpublishing)
      expect(unpublishing.type).to eq("gone")

      # successfully created an unpublishing, now try to modify it
      expect {
        unpublishing = described_class.unpublish(live_item,
                                  type: "redirect",
                                  explanation: "A test explanation",
                                  alternative_path: "/redirected-some-path",
        )
      }.to change(Unpublishing, :count).by(0)

      last_unpublishing = Unpublishing.last
      expect(unpublishing).to eq(last_unpublishing)
      expect(unpublishing.type).to eq("redirect")
      expect(unpublishing.alternative_path).to eq("/redirected-some-path")
    end
  end

  describe ".substitute" do
    let(:live_item) { FactoryGirl.create(:live_content_item) }
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
