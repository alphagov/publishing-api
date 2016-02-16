require "rails_helper"

RSpec.describe UserFacingVersion do
  describe "validations" do
    let(:content_id) { SecureRandom.uuid }

    let!(:draft) do
      FactoryGirl.create(
        :draft_content_item,
        content_id: content_id,
      )
    end

    let!(:live) do
      FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
      )
    end

    let(:draft_version) { described_class.find_by!(content_item: draft) }
    let(:live_version) { described_class.find_by!(content_item: live) }

    context "when another content item has identical supporting objects" do
      before do
        FactoryGirl.create(:content_item, user_facing_version: 3)
      end

      let(:content_item) do
        FactoryGirl.create(:content_item, user_facing_version: 2)
      end

      subject {
        FactoryGirl.build(:user_facing_version, content_item: content_item, number: 3)
      }

      it "is invalid" do
        expect(subject).to be_invalid

        error = subject.errors[:content_item].first
        expect(error).to match(/conflicts with/)
      end
    end

    context "when the draft version is behind the live version" do
      before do
        draft_version.number = 1
        draft_version.save!(validate: false)

        live_version.number = 2
        live_version.save!(validate: false)
      end

      it "makes the draft version invalid" do
        expect(draft_version).to be_invalid

        expect(draft_version.errors[:number]).to include(
          "draft version cannot be behind the live version (1 < 2)"
        )
      end

      it "makes the live version invalid" do
        expect(live_version).to be_invalid

        expect(live_version.errors[:number]).to include(
          "draft version cannot be behind the live version (1 < 2)"
        )
      end
    end

    context "when the draft version is equal to the live version" do
      before do
        draft_version.number = 2
        live_version.number = 2
      end

      it "has a valid draft version" do
        expect(draft_version).to be_valid
      end

      it "has a valid live version" do
        draft_version.save!
        expect(live_version).to be_valid
      end
    end

    context "when the draft version is ahead of the live version" do
      before do
        draft_version.number = 3
        live_version.number = 2
      end

      it "has a valid draft version" do
        expect(draft_version).to be_valid
      end

      it "has a valid live version" do
        draft_version.save!
        expect(live_version).to be_valid
      end
    end
  end

  describe ".latest" do
    before do
      FactoryGirl.create(:content_item, user_facing_version: 2, title: "Latest")
      FactoryGirl.create(:content_item, user_facing_version: 1)
    end

    it "returns the content item with the latest user facing version" do
      item = described_class.latest(ContentItem.all)
      expect(item.title).to eq("Latest")
    end
  end
end
