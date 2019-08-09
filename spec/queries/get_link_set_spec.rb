require "rails_helper"

RSpec.describe Queries::GetLinkSet do
  let(:content_id) { SecureRandom.uuid }

  context "when the link set exists" do
    let!(:link_set) do
      create(:link_set, content_id: content_id, stale_lock_version: 5)
    end

    context "and it has some links" do
      let(:parent) { [SecureRandom.uuid] }
      let(:related) { [SecureRandom.uuid, SecureRandom.uuid] }

      before do
        create(:link,
               link_set: link_set,
               link_type: "parent",
               target_content_id: parent.first)

        create(:link,
               link_set: link_set,
               link_type: "related",
               target_content_id: related.first)

        create(:link,
               link_set: link_set,
               link_type: "related",
               target_content_id: related.last)
      end

      it "returns the content_id, lock_version and links grouped by link_type" do
        result = subject.call(content_id)

        expect(result).to eq(
          content_id: content_id,
          version: 5,
          links: {
            parent: parent,
            related: related,
          }
        )
      end
    end

    context "and it doesn't have any links" do
      it "returns the content_id, lock_version and an empty links hash" do
        result = subject.call(content_id)

        expect(result).to eq(
          content_id: content_id,
          version: 5,
          links: {},
        )
      end
    end
  end

  context "when the document does not exist" do
    it "raises a command error" do
      expect {
        subject.call(content_id)
      }.to raise_error(CommandError, /could not find link set/i)
    end
  end

  context "when a document exists without a link set" do
    before do
      create(:document, content_id: content_id)
    end

    it "returns an empty response" do
      result = subject.call(content_id)

      expect(result).to eq(
        content_id: content_id,
        version: 0,
        links: {},
      )
    end
  end
end
