require "rails_helper"

RSpec.describe Queries::GetExpandedLinks do
  let(:content_id) { SecureRandom.uuid }
  let(:live_child_taxon_content_id) { SecureRandom.uuid }
  let(:draft_child_taxon_content_id) { SecureRandom.uuid }

  context "when the document does not exist" do
    it "raises a command error" do
      expect {
        described_class.call(content_id, "en")
      }.to raise_error(CommandError, /could not find link set/i)
    end
  end

  context "when a document exists without a link set" do
    before do
      FactoryGirl.create(:document, content_id: content_id)
    end

    it "returns an empty response" do
      result = described_class.call(content_id, "en")

      expect(result).to eq(
        content_id: content_id,
        version: 0,
        expanded_links: {},
      )
    end
  end

  context "when a document exists with a link set" do
    before do
      document = FactoryGirl.create(:document, content_id: content_id)
      FactoryGirl.create(:live_edition, document: document, base_path: '/foo')

      FactoryGirl.create(:live_edition,
        document: Document.find_or_create_by(
          content_id: live_child_taxon_content_id,
          locale: "en"
        ),
        base_path: "/foo/bar",
        user_facing_version: 1,
        links_hash: {
          parent_taxons: [content_id]
        },
      )
      FactoryGirl.create(:draft_edition,
        document: Document.find_or_create_by(
          content_id: draft_child_taxon_content_id,
          locale: "en"
        ),
        base_path: "/foo/baz",
        user_facing_version: 1,
        links_hash: {
          parent_taxons: [content_id]
        },
      )
      FactoryGirl.create(:link_set,
        content_id: content_id,
        links_hash: {},
      )
    end

    it "returns all links by default" do
      result = described_class.call(content_id, "en")
      expect(result[:expanded_links][:child_taxons]).to match_array(
        [
          hash_including(content_id: live_child_taxon_content_id),
          hash_including(content_id: draft_child_taxon_content_id),
        ]
      )
    end

    it "returns only links to live editions when with_drafts is false" do
      result = described_class.call(content_id, "en", with_drafts: false)

      expect(result[:expanded_links][:child_taxons]).to match_array(
        [
          hash_including(content_id: live_child_taxon_content_id),
        ]
      )
    end

    it "fetches links from the cache" do
      expect(Rails.cache).to receive(:fetch).with(["expanded-link-set", content_id, "en", false])

      described_class.call(content_id, "en", with_drafts: false)
    end
  end
end
