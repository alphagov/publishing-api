require "rails_helper"

RSpec.describe Tasks::VersionValidator do
  let(:content_id) { SecureRandom.uuid }

  before do
    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      state: "superseded",
      user_facing_version: 1,
      locale: "en"
    )

    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      state: "published",
      user_facing_version: 2,
      locale: "en"
    )
  end

  context "when there are no version sequence problems" do
    it "does not output any problems" do
      expect {
        subject.validate
      }.not_to output(/Invalid version sequence/).to_stdout
    end
  end

  context "when two items of the same content_id have identical versions" do
    before do
      version = UserFacingVersion.last
      version.number = 1
      version.save!(validate: false)
    end

    it "outputs that the content item has an invalid version sequence" do
      expect {
        subject.validate
      }.to output(/Invalid version sequence for #{content_id}/).to_stdout
    end

    context "but the content items have different locales" do
      before do
        translation = Translation.last
        translation.locale = "fr"
        translation.save!(validate: false)
      end

      it "does not output any problems" do
        expect {
          subject.validate
        }.not_to output(/Invalid version sequence/).to_stdout
      end
    end
  end

  context "when the version sequence does not begin at zero" do
    before do
      version = UserFacingVersion.first
      version.number = 3
      version.save!(validate: false)
    end

    it "outputs that the content item has an invalid version sequence" do
      expect {
        subject.validate
      }.to output(/Invalid version sequence for #{content_id}/).to_stdout
    end
  end
end
