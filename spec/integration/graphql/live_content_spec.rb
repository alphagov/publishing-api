RSpec.describe "Requesting live content by base path" do
  schema_specific_fields = {
    news_article: { details: { body: "" } },
    publication: { details: { body: "", documents: [], political: false } },
    world_index: {
      details: { world_locations: [], international_delegations: [] },
    },
  }

  Dir.children(Rails.root.join("app/graphql/queries")).each do |query_filename|
    schema_name = query_filename.split(".").first

    context "when the edition is a #{schema_name}" do
      # NOTE: this should not be taken as evidence that we produce a valid
      # response for real data. We can't guarantee that the factory-generated
      # edition looks like real data, so this won't catch certain issues
      it "can produce a response that is valid against the schema" do
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

        expect(errors).to eql([]), errors.join("\n")
      end
    end
  end
end
