require "rails_helper"

RSpec.describe UserFacingVersion do
  subject { build(:user_facing_version) }

  it "starts version numbers at 0" do
    content_item = create(:content_item)
    user_facing_version = UserFacingVersion.create(content_item: content_item)

    expect(user_facing_version.number).to be_zero
    expect(user_facing_version).to be_valid
  end

  describe "#increment" do
    it "adds one to the number" do
      subject.increment
      expect(subject.number).to eq(2)

      subject.increment
      expect(subject.number).to eq(3)
    end
  end

  describe ".latest" do
    before do
      create(:content_item, user_facing_version: 2, title: "Latest")
      create(:content_item, user_facing_version: 1)
    end

    it "returns the content item with the latest user_facing version" do
      item = described_class.latest(ContentItem.all)
      expect(item.title).to eq("Latest")
    end
  end

  describe "validations" do
    let(:content_id) { SecureRandom.uuid }

    let!(:draft) do
      create(
        :draft_content_item,
        content_id: content_id,
      )
    end

    let!(:live) do
      create(
        :live_content_item,
        content_id: content_id,
      )
    end

    let(:draft_version) { described_class.find_by!(content_item: draft) }
    let(:live_version) { described_class.find_by!(content_item: live) }

    context "when another content item has identical supporting objects" do
      before do
        create(:content_item, user_facing_version: 3)
      end

      let(:content_item) do
        create(:content_item, user_facing_version: 2)
      end

      subject {
        build(:user_facing_version, content_item: content_item, number: 3)
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
          "draft UserFacingVersion cannot be behind the live UserFacingVersion (1 < 2)"
        )
      end

      it "makes the live version invalid" do
        expect(live_version).to be_invalid

        expect(live_version.errors[:number]).to include(
          "draft UserFacingVersion cannot be behind the live UserFacingVersion (1 < 2)"
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
end
