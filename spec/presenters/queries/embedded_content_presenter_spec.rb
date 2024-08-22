RSpec.describe Presenters::Queries::EmbeddedContentPresenter do
  describe "#present" do
    let(:organisation_edition_id) { SecureRandom.uuid }
    let(:target_edition_id) { SecureRandom.uuid }

    let(:host_editions) do
      [double("Edition",
              id: "1",
              title: "foo",
              base_path: "/foo",
              document_type: "publication",
              primary_publishing_organisation_content_id: organisation_edition_id,
              primary_publishing_organisation_title: "bar",
              primary_publishing_organisation_base_path: "/bar")]
    end

    let(:result) { described_class.present(target_edition_id, host_editions) }

    let(:expected_output) do
      {
        content_id: target_edition_id,
        total: 1,
        results: [
          {
            title: "foo",
            base_path: "/foo",
            document_type: "publication",
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
