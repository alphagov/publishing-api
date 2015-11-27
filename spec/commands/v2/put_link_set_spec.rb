require "rails_helper"

RSpec.describe Commands::V2::PutLinkSet do
  describe "#call" do
    it "requires links to be sent" do
      link_params_with_missing_links = {}

      expect {
        put_link_set(link_params_with_missing_links)
      }.to raise_error(CommandError, "Links are required")
    end

    it "creates one links" do
      link_set = create(:link_set)
      link_content_id = SecureRandom.uuid

      put_link_set(
        content_id: link_set.content_id,
        links: {
          topics: [link_content_id]
        }
      )

      expect(link_set.links.map(&:target_content_id)).to eql([link_content_id])
    end

    it "creates multiple new links" do
      link_set = create(:link_set)
      link_content_ids = [SecureRandom.uuid, SecureRandom.uuid]

      put_link_set(
        content_id: link_set.content_id,
        links: {
          topics: link_content_ids
        }
      )

      expect(link_set.links.map(&:target_content_id)).to eql(link_content_ids)
    end

    it "deletes all links from an existing link set" do
      link_set = create(:link_set)
      link = create(:link, link_set: link_set, link_type: "topics")

      put_link_set(
        content_id: link_set.content_id,
        links: {
          topics: []
        }
      )

      expect { link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "deletes some links from an existing link set" do
      link_set = create(:link_set)
      link_to_keep = create(:link, link_set: link_set, link_type: "topics")
      link_to_be_deleted = create(:link, link_set: link_set, link_type: "topics")

      put_link_set(
        content_id: link_set.content_id,
        links: {
          topics: [link_to_keep.target_content_id],
        }
      )

      expect(link_set.links.map(&:target_content_id)).to eql([link_to_keep.target_content_id])
    end

    it "does nothing when the links haven't changed" do
      link_set = create(:link_set)
      link_to_keep = create(:link, link_set: link_set, link_type: "topics")

      put_link_set(
        content_id: link_set.content_id,
        links: {
          topics: [link_to_keep.target_content_id],
        }
      )

      expect(link_set.links.map(&:target_content_id)).to eql([link_to_keep.target_content_id])
    end

    def put_link_set(links)
      Commands::V2::PutLinkSet.call(links)
    end
  end
end
