RSpec.describe Queries::ReverseLinkedToEditions do
  subject(:query) { described_class.new(locale: "en", with_drafts:) }

  let(:with_drafts) { false }

  describe "#call" do
    it "returns a hash keyed by [target_content_id, link_type], seeded with empty arrays" do
      target = create(:live_edition)

      result = query.call([[target, "test_link"]])

      expect(result).to eq({ [target.content_id, "test_link"] => [] })
    end

    it "groups found source editions under the target content_id and link type" do
      target = create(:live_edition, title: "target")
      source = create(:live_edition,
                      title: "source",
                      link_set_links: [
                        { link_type: "test_link", target_content_id: target.content_id },
                      ])

      result = query.call([[target, "test_link"]])

      expect(result[[target.content_id, "test_link"]].map(&:content_id))
        .to eq([source.content_id])
    end

    it "preserves the order of the input keys" do
      target_a = create(:live_edition)
      target_b = create(:live_edition)

      result = query.call([[target_b, "b_link"], [target_a, "a_link"]])

      expect(result.keys).to eq([
        [target_b.content_id, "b_link"],
        [target_a.content_id, "a_link"],
      ])
    end

    it "returns an empty hash for empty input without issuing a query" do
      expect(Edition).not_to receive(:find_by_sql)
      expect(query.call([])).to eq({})
    end
  end
end
