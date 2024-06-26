RSpec.describe Queries::GetLinkChanges do
  describe "#as_hash" do
    it "returns the link changes with the correct data" do
      link_change = create(:link_change, link_type: "taxons")

      result = Queries::GetLinkChanges.new(link_types: "taxons").as_hash

      change = result[:link_changes].first.deep_symbolize_keys

      expect(change.keys).to match_array(
        %i[source target link_type change user_uid created_at],
      )
      expect(change[:created_at]).to eql(link_change.created_at.utc.iso8601)
    end

    it "expands the source and target" do
      document = create(:document, content_id: "1dd96f5d-c260-438b-ba58-57ba910e9291")
      create(:edition, document:, title: "Content Foo")
      create(:link_change, link_type: "taxons", source_content_id: document.content_id)

      result = Queries::GetLinkChanges.new(link_types: "taxons").as_hash

      change = result[:link_changes].first.deep_symbolize_keys
      expect(change[:source].keys).to match_array(%i[title base_path content_id])
    end
  end
end
