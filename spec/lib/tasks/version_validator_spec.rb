require "rails_helper"

RSpec.describe Tasks::VersionValidator do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id: content_id) }

  before do
    create(:superseded_edition,
      document: document,
      user_facing_version: 1)

    create(:live_edition,
      document: document,
      user_facing_version: 2)
  end

  context "when there are no version sequence problems" do
    it "does not output any problems" do
      expect {
        subject.validate
      }.not_to output(/Invalid version sequence/).to_stdout
    end
  end

  context "when two items of the same content_id have a gap between versions" do
    before do
      item = Edition.last
      item.user_facing_version = 3
      item.save!(validate: false)
    end

    it "outputs that the edition has an invalid version sequence" do
      expect {
        subject.validate
      }.to output(/Invalid version sequence for #{content_id}/).to_stdout
    end
  end

  context "when editions have the same version but different locale" do
    before do
      item = Edition.last
      item.document = create(:document,
        content_id: item.document.content_id,
        locale: "fr")
      item.user_facing_version = 1
      item.save!(validate: false)
    end

    it "does not output any problems" do
      expect {
        subject.validate
      }.not_to output(/Invalid version sequence/).to_stdout
    end
  end

  context "when the version sequence does not begin at zero" do
    before do
      item = Edition.first
      item.user_facing_version = 3
      item.save!(validate: false)
    end

    it "outputs that the edition has an invalid version sequence" do
      expect {
        subject.validate
      }.to output(/Invalid version sequence for #{content_id}/).to_stdout
    end
  end
end
