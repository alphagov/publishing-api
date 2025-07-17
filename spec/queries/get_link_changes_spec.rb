RSpec.describe Queries::GetLinkChanges do
  describe "#as_hash" do
    it "expands the source and target" do
      source_document = create(:document)
      source_edition = create(:edition, document: source_document)

      target_document = create(:document)
      target_edition = create(:edition, document: target_document)

      link_change = create(:link_change,
                           link_type: "taxons",
                           source_content_id: source_document.content_id,
                           target_content_id: target_document.content_id,
                           created_at: "2025-07-17 00:01:01")

      result = Queries::GetLinkChanges.new(link_types: "taxons").as_hash

      expect(result[:link_changes]).to eq([{
        source: {
          title: source_edition.title,
          base_path: source_edition.base_path,
          content_id: source_edition.content_id,
        },
        target: {
          title: target_edition.title,
          base_path: target_edition.base_path,
          content_id: target_edition.content_id,
        },
        link_type: link_change.link_type,
        change: link_change.change,
        created_at: link_change.created_at,
        user_uid: link_change.action.user_uid,
      }])
    end
  end
end
