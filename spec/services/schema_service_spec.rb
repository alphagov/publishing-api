RSpec.describe SchemaService do
  describe "#all_schemas" do
    let(:schemas) do
      {
        "/govuk/publishing-api/content_schemas/dist/formats/foo/publisher_v2/schema.json": {
          type: "object",
          required: %w[a],
          properties: {
            a: { "type" => "integer" },
          },
        },
        "/govuk/publishing-api/content_schemas/dist/formats/bar/publisher_v2/links.json": {
          type: "object",
          required: %w[a],
          properties: {
            a: { "type" => "integer" },
          },
        },
        "/govuk/publishing-api/content_schemas/dist/formats/baz/publisher_v2/schema.json": {
          type: "object",
          required: %w[a],
          properties: {
            a: { "type" => "integer" },
          },
        },
      }.with_indifferent_access
    end

    before do
      allow(GovukSchemas::Schema).to receive(:all).with(schema_type: "publisher") { schemas }
    end

    it "returns all schemas" do
      expected_schemas = {
        "foo": schemas[:"/govuk/publishing-api/content_schemas/dist/formats/foo/publisher_v2/schema.json"],
        "baz": schemas[:"/govuk/publishing-api/content_schemas/dist/formats/baz/publisher_v2/schema.json"],
      }.with_indifferent_access

      expect(SchemaService.all_schemas).to eq(expected_schemas)
    end
  end
end
