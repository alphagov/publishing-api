RSpec.describe Presenters::EmbeddedContentPresenter do
  describe "#present" do
    let(:organisation_edition_id) { SecureRandom.uuid }
    let(:target_edition_id) { SecureRandom.uuid }
    let(:last_edited_by_editor_id) { SecureRandom.uuid }
    let(:last_edited_at) { 2.days.ago }
    let(:total) { 222 }
    let(:total_pages) { 23 }

    let(:host_editions) do
      [double("Queries::GetEmbeddedContent::Result",
              id: "1",
              title: "foo",
              base_path: "/foo",
              document_type: "publication",
              publishing_app: "publisher",
              last_edited_by_editor_id:,
              last_edited_at:,
              unique_pageviews: 123,
              primary_publishing_organisation_content_id: organisation_edition_id,
              primary_publishing_organisation_title: "bar",
              primary_publishing_organisation_base_path: "/bar",
              instances: 1)]
    end

    let(:result) { described_class.present(target_edition_id, host_editions, total, total_pages) }

    let(:expected_output) do
      {
        content_id: target_edition_id,
        total:,
        total_pages:,
        results: [
          {
            title: "foo",
            base_path: "/foo",
            document_type: "publication",
            publishing_app: "publisher",
            last_edited_by_editor_id:,
            last_edited_at:,
            unique_pageviews: 123,
            instances: 1,
            primary_publishing_organisation: {
              content_id: organisation_edition_id,
              title: "bar",
              base_path: "/bar",
            },
          },
        ],
      }
    end

    it "presents attributes of host content in an array of results" do
      expect(result).to eq(expected_output)
    end
  end
end