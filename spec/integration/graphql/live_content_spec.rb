RSpec.describe "Requesting live content by base path" do
  schema_specific_fields = {
    news_article: { details: { body: "" } },
    world_index: {
      details: { world_locations: [], international_delegations: [] },
    },
  }

  Dir.children(Rails.root.join("app/graphql/queries")).each do |query_filename|
    schema_name = query_filename.split(".").first

    context "when the edition is a #{schema_name}" do
      it "produces a response that is valid against the schema" do
        schema = GovukSchemas::Schema.find(frontend_schema: schema_name)
        document_type = schema.dig("properties", "document_type", "enum").sample
        edition = create(
          :live_edition,
          schema_name:,
          document_type:,
          **schema_specific_fields.fetch(schema_name.to_sym, {}),
        )

        get "/graphql/content/#{edition.base_path}"

        parsed_response = JSON.parse(response.body)
        errors = JSON::Validator.fully_validate(schema, parsed_response)

        expect(errors).to eql([])
      end
    end
  end
end
