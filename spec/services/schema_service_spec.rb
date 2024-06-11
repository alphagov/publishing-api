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

  describe "find_schema_by_name" do
    let(:schema) do
      {
        type: "other",
        required: %w[b],
        properties: {
          b: { "type" => "string" },
        },
      }.with_indifferent_access
    end

    describe "when a schema exists" do
      before do
        allow(GovukSchemas::Schema).to receive(:find).with(publisher_schema: "other") { schema }
      end

      it "returns a schema" do
        expect(SchemaService.find_schema_by_name("other")).to eq(schema)
      end
    end

    describe "when a schema does not exist" do
      before do
        allow(GovukSchemas::Schema).to receive(:find).with(publisher_schema: "any").and_raise(Errno::ENOENT)
      end

      it "throws an error" do
        expect { SchemaService.find_schema_by_name("any") }.to raise_error(
          an_instance_of(CommandError).and(having_attributes(code: 404, message: "Could not find publisher schema with name: any")),
        )
      end
    end
  end
end
