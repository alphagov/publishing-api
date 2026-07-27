RSpec.describe Queries::LinkedToEditions do
  subject(:query) { described_class.new(locale: "en", with_drafts:) }

  let(:with_drafts) { false }

  describe "#call" do
    it "returns a hash keyed by [source_content_id, link_type], seeded with empty arrays" do
      source = create(:live_edition)

      result = query.call([[source, "test_link"]])

      expect(result).to eq({ [source.content_id, "test_link"] => [] })
    end

    it "groups found editions under the source content_id and link type" do
      target = create(:live_edition, title: "target")
      source = create(:live_edition,
                      link_set_links: [
                        { link_type: "test_link", target_content_id: target.content_id },
                      ])

      result = query.call([[source, "test_link"]])

      expect(result[[source.content_id, "test_link"]].map(&:content_id))
        .to eq([target.content_id])
    end

    it "preserves the order of the input keys" do
      source_a = create(:live_edition)
      source_b = create(:live_edition)

      result = query.call([[source_b, "b_link"], [source_a, "a_link"]])

      expect(result.keys).to eq([
        [source_b.content_id, "b_link"],
        [source_a.content_id, "a_link"],
      ])
    end

    it "returns an empty hash for empty input without issuing a query" do
      expect(Edition).not_to receive(:find_by_sql)
      expect(query.call([])).to eq({})
    end

    context "with a struct carrying a nil edition_id (the BFS non-root input)" do
      let(:node) { Struct.new(:id, :content_id) }

      it "matches only link set links (edition links require a non-null edition_id)" do
        target_for_link_set = create(:live_edition, title: "link set target")
        target_for_edition = create(:live_edition, title: "edition link target")

        source = create(:live_edition,
                        link_set_links: [
                          { link_type: "test_link", target_content_id: target_for_link_set.content_id },
                        ],
                        edition_links: [
                          { link_type: "test_link", target_content_id: target_for_edition.content_id },
                        ])

        # Passing edition_id: nil (as the BFS does at child levels) means the
        # edition_linked_editions CTE matches nothing, so only the link set link
        # is returned.
        result = query.call([[node.new(nil, source.content_id), "test_link"]])

        expect(result[[source.content_id, "test_link"]].map(&:content_id))
          .to eq([target_for_link_set.content_id])
      end
    end
  end
end
