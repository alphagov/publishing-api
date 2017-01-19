require "rails_helper"

RSpec.describe State do
  describe "validations" do
    subject { FactoryGirl.build(:state) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end

  describe ".unpublish" do
    let(:live_item) { FactoryGirl.create(:live_content_item) }

    it "changes the state name to 'unpublished'" do
      expect {
        live_item.unpublish(type: "gone")
      }.to change { live_item.reload.state }.to("unpublished")
    end

    it "creates an unpublishing" do
      expect {
        live_item.unpublish(
          type: "gone",
          explanation: "A test explanation",
          alternative_path: "/some-path",
        )
      }.to change(Unpublishing, :count).by(1)

      unpublishing = Unpublishing.last

      expect(unpublishing.edition).to eq(live_item)
      expect(unpublishing.type).to eq("gone")
      expect(unpublishing.explanation).to eq("A test explanation")
      expect(unpublishing.alternative_path).to eq("/some-path")
    end

    it "updates an existing unpublishing" do
      unpublishing = nil
      expect {
        unpublishing = live_item.unpublish(
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
        unpublishing = live_item.unpublish(
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
end
