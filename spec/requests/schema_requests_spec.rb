RSpec.describe "Schema requests", type: :request do
  describe "GET /v2/schemas" do
    let(:schemas) do
      {
        "foo": { "some": "schema" },
        "bar": { "another": "schema" },
      }.with_indifferent_access
    end

    before do
      allow(SchemaService).to receive(:all_schemas) { schemas }
    end

    it "returns all schemas" do
      get "/v2/schemas"

      expect(parsed_response).to eq(schemas)
    end
  end

  describe "GET /v2/schemas/:schema_name" do
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
        allow(SchemaService).to receive(:find_schema_by_name).with("other") { schema }
      end

      it "returns a schema" do
        get "/v2/schemas/other"

        expect(parsed_response).to eq(schema)
      end
    end

    describe "when a schema does not exist" do
      before do
        allow(GovukSchemas::Schema).to receive(:find).and_raise(CommandError.new(code: 404, message: "some message"))
      end

      it "returns 404" do
        get "/v2/schemas/other"

        expect(response.status).to eql 404
      end
    end
  end
end
