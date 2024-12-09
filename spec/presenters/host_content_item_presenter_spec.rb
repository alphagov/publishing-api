RSpec.describe Presenters::HostContentItemPresenter do
  describe "#present" do
    let(:organisation_edition_id) { SecureRandom.uuid }
    let(:last_edited_by_editor_id) { SecureRandom.uuid }
    let(:host_content_id) { SecureRandom.uuid }
    let(:last_edited_at) { 2.days.ago }

    let(:host_edition) do
      double("Queries::GetHostContent::Result",
             id: "1",
             title: "foo",
             base_path: "/foo",
             document_type: "publication",
             publishing_app: "publisher",
             last_edited_by_editor_id:,
             last_edited_at:,
             unique_pageviews: 123,
             host_content_id:,
             primary_publishing_organisation_content_id: organisation_edition_id,
             primary_publishing_organisation_title: "bar",
             primary_publishing_organisation_base_path: "/bar",
             instances: 1)
    end

    let(:result) { described_class.present(host_edition) }

    let(:expected_output) do
      {
        title: "foo",
        base_path: "/foo",
        document_type: "publication",
        publishing_app: "publisher",
        last_edited_by_editor_id:,
        last_edited_at:,
        unique_pageviews: 123,
        instances: 1,
        host_content_id: host_content_id,
        primary_publishing_organisation: {
          content_id: organisation_edition_id,
          title: "bar",
          base_path: "/bar",
        },
      }
    end

    it "presents a single host content item" do
      expect(result).to eq(expected_output)
    end
  end
end
