RSpec.describe Presenters::HostContentPresenter do
  describe "#present" do
    let(:organisation_edition_id) { SecureRandom.uuid }
    let(:target_edition_id) { SecureRandom.uuid }
    let(:last_edited_by_editor_id) { SecureRandom.uuid }
    let(:host_content_id) { SecureRandom.uuid }
    let(:last_edited_at) { 2.days.ago }
    let(:total) { 222 }
    let(:total_pages) { 23 }

    let(:host_editions) do
      [double("Queries::GetHostContent::Result",
              id: "1",
              title: "foo",
              base_path: "/foo",
              document_type: "publication",
              publishing_app: "publisher",
              last_edited_by_editor_id:,
              last_edited_at:,
              unique_pageviews: 123,
              host_content_id:,
              host_locale: "en",
              primary_publishing_organisation_content_id: organisation_edition_id,
              primary_publishing_organisation_title: "bar",
              primary_publishing_organisation_base_path: "/bar",
              instances: 1)]
    end

    let(:rollup) do
      double("Queries::GetHostContent::Rollup",
             views: "123",
             locations: 1,
             instances: 4.0,
             organisations: 2)
    end

    let(:result) { described_class.present(target_edition_id, host_editions, total, total_pages, rollup) }

    let(:expected_output) do
      {
        content_id: target_edition_id,
        total:,
        total_pages:,
        rollup: {
          views: 123,
          locations: 1,
          instances: 4,
          organisations: 2,
        },
        results: [
          Presenters::HostContentItemPresenter.present(host_editions[0]),
        ],
      }
    end

    it "presents attributes of host content in an array of results" do
      expect(result).to eq(expected_output)
    end

    context "when any rollup values are not present" do
      let(:rollup) do
        double("Queries::GetHostContent::Rollup",
               views: nil,
               locations: nil,
               instances: "",
               organisations: nil)
      end

      it "returns zeroes for those values" do
        expect(result[:rollup]).to eq({
          views: 0,
          locations: 0,
          instances: 0,
          organisations: 0,
        })
      end
    end
  end
end
