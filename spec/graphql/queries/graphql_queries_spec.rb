RSpec.describe "GraphQL queries" do
  include LinkExpansionHelpers

  Dir[Rails.root.join("app/graphql/queries/*.graphql")].each do |path|
    /(?<schema_name>[^\/]+)[.]graphql\Z/ =~ path

    context schema_name do
      let(:json_schema) do
        JSON.load_file(Rails.root.join("content_schemas/dist/formats/#{schema_name}/frontend/schema.json"))
      end
      let(:link_paths_for_schema) do
        expected_link_paths_for_schema(schema_name, json_schema, GraphqlQueryBuilder::MAX_LINK_DEPTH)
      end

      it "should have the same top level fields as the JSON schema" do
        ast = GraphQL.parse_file(path)
        visitor = TopLevelFieldsVisitor.new(ast)
        visitor.visit

        top_level_json_schema_fields = json_schema.fetch("properties").keys.to_set
        details_json_schema_fields = (json_schema.dig("definitions", "details", "properties") || {}).keys.to_set

        expect(visitor.top_level_graphql_query_fields).to match_array(top_level_json_schema_fields)
        expect(visitor.details_graphql_query_fields).to match_array(details_json_schema_fields)
      end

      it "should include all of the expected link paths from the expansion rules" do
        ast = GraphQL.parse_file(path)
        visitor = LinkPathsVisitor.new(ast)
        visitor.visit

        expect(visitor.link_paths).to match_array(link_paths_for_schema)
      end
    end
  end
end
