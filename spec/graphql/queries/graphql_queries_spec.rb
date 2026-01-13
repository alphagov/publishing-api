RSpec::Matchers.define :match_array_with_link_path do |expected, link_path|
  match do |actual|
    @actual = actual
    @matcher = RSpec::Matchers::BuiltIn::ContainExactly.new(expected)
    @matcher.matches?(actual)
  end

  failure_message { "%-32s%s\n%s" % ["at link path:", link_path, @matcher.failure_message] }
end

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

      it "should select the same top level fields as the JSON schema" do
        ast = GraphQL.parse_file(path)
        visitor = TopLevelFieldsVisitor.new(ast)
        visitor.visit

        top_level_json_schema_fields = json_schema.fetch("properties").keys.to_set
        details_json_schema_fields = (json_schema.dig("definitions", "details", "properties") || {}).keys.to_set

        expect(visitor.top_level_graphql_query_fields).to match_array(top_level_json_schema_fields)
        expect(visitor.details_graphql_query_fields).to match_array(details_json_schema_fields)
      end

      it "should match the expected link paths from the expansion rules" do
        ast = GraphQL.parse_file(path)
        visitor = LinkPathsVisitor.new(ast)
        visitor.visit

        expect(visitor.full_link_paths).to match_array(link_paths_for_schema)
      end

      it "should select the same linked fields as the expansion rules" do
        ast = GraphQL.parse_file(path)
        visitor = LinkPathsVisitor.new(ast)
        visitor.visit

        aggregate_failures do
          gqb = GraphqlQueryBuilder.new(schema_name)
          visitor.selections_by_link_path.each do |link_path, selections|
            next if link_path == [:lead_organisations] # TODO: why does this have an extra public_updated_at ?

            link = gqb.build_link(link_path)
            next if link.nil?

            expected_selections = link.keys.map(&:to_sym) - %i[withdrawn]

            expect(selections - %i[links]).to match_array_with_link_path(expected_selections, link_path)
          end
        end
      end
    end
  end
end
