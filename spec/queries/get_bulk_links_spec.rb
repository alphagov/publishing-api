require "rails_helper"

RSpec.describe Queries::GetBulkLinks do
  subject { described_class }
  let(:content_id_with_links) { SecureRandom.uuid }
  let(:content_id_no_links) { SecureRandom.uuid }

  let(:parent) { [SecureRandom.uuid] }
  let(:related) { [SecureRandom.uuid, SecureRandom.uuid] }

  let(:link_set) do
    {
      links: {
        parent: parent,
        related: related,
      },
      version: 5,
    }
  end

  let(:empty_link_set) { { links: {}, version: 0 } }

  before do
    link_set = create(
      :link_set,
      content_id: content_id_with_links,
      stale_lock_version: 5,
    )

    create(
      :link,
      link_set: link_set,
      link_type: "parent",
      target_content_id: parent.first,
    )

    create(
      :link,
      link_set: link_set,
      link_type: "related",
      target_content_id: related.first,
    )

    create(
      :link,
      link_set: link_set,
      link_type: "related",
      target_content_id: related.last,
    )
  end

  describe ".call" do
    it "returns a hash of content_ids => links" do
      content_ids = [content_id_with_links, content_id_no_links]
      result = subject.call(content_ids)

      expect(result.keys).to eql content_ids
      expect(result[content_id_with_links]).to eql link_set
      expect(result[content_id_no_links]).to eql empty_link_set
    end
  end
end
