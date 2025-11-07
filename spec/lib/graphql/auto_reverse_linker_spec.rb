RSpec.describe Graphql::AutoReverseLinker do
  subject(:linker) { described_class.new(edition) }

  describe "#insert_links" do
    let(:edition) do
      build(
        :live_edition,
        document: create(
          :document,
          content_id: "5f41f054-7631-11e4-a3cb-005056011aef",
          locale: "en",
        ),
        analytics_identifier: "PUB1",
        base_path: "/government/publications/air-passenger-duty-banding-reform",
        document_type: "policy_paper",
        public_updated_at: "2015-02-17T11:22:08Z",
        schema_name: "publication",
        title: "Air Passenger Duty: banding reform",
      )
    end

    it "gives top-level reverse links a nested link back to the root edition" do
      content_item = {
        "base_path" => "/government/publications/air-passenger-duty-banding-reform",
        "content_id" => "5f41f054-7631-11e4-a3cb-005056011aef",
        "document_type" => "policy_paper",
        "links" => {
          "document_collections" => [
            {
              "api_path" => "/api/content/government/collections/air-passenger-duty-tax-information-and-impact-notes",
              "api_url" => "http://www.dev.gov.uk/api/content/government/collections/air-passenger-duty-tax-information-and-impact-notes",
              "base_path" => "/government/collections/air-passenger-duty-tax-information-and-impact-notes",
              "content_id" => "37fd3173-8eb2-4e1a-aa70-b2096aed3044",
              "document_type" => "document_collection",
              "links" => {},
              "locale" => "en",
              "public_updated_at" => "2013-11-14T00:00:00Z",
              "schema_name" => "document_collection",
              "title" => "Air Passenger Duty: Tax Information and Impact Notes",
              "web_url" => "http://www.dev.gov.uk/government/collections/air-passenger-duty-tax-information-and-impact-notes",
            },
          ],
        },
        "locale" => "en",
        "public_updated_at" => "2015-02-17T11:22:08Z",
        "schema_name" => "publication",
        "title" => "Air Passenger Duty: banding reform",
      }

      updated_content_item = linker.insert_links(content_item)

      document_collections = updated_content_item.dig("links", "document_collections")
      expect(document_collections.size).to eq(1)

      documents = document_collections.first.dig("links", "documents")
      expect(documents.size).to eq(1)

      expect(documents.first).to eq(
        {
          "analytics_identifier" => "PUB1",
          "api_path" => "/api/content/government/publications/air-passenger-duty-banding-reform",
          "api_url" => "http://www.dev.gov.uk/api/content/government/publications/air-passenger-duty-banding-reform",
          "base_path" => "/government/publications/air-passenger-duty-banding-reform",
          "content_id" => "5f41f054-7631-11e4-a3cb-005056011aef",
          "document_type" => "policy_paper",
          "links" => {},
          "locale" => "en",
          "public_updated_at" => "2015-02-17T11:22:08Z",
          "schema_name" => "publication",
          "title" => "Air Passenger Duty: banding reform",
          "web_url" => "http://www.dev.gov.uk/government/publications/air-passenger-duty-banding-reform",
          "withdrawn" => false,
        },
      )
    end
  end
end
