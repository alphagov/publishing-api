class TopLevelFieldsVisitor < GraphQL::Language::Visitor
  attr_reader :top_level_graphql_query_fields, :details_graphql_query_fields

  def on_field(node, _parent)
    return unless node.is_a?(GraphQL::Language::Nodes::Field) && node.name == "edition"

    fields = case node.selections
             in [GraphQL::Language::Nodes::InlineFragment => inline_fragment]
               inline_fragment.selections
             end

    @top_level_graphql_query_fields = fields.map(&:name).to_set
    @details_graphql_query_fields = fields.find { _1.name == "details" }&.selections&.map(&:name)&.to_set
  end
end

RSpec.describe "GraphQL queries" do
  Dir[Rails.root.join("app/graphql/queries/*.graphql")].each do |path|
    /(?<schema_name>[^\/]+)[.]graphql\Z/ =~ path

    it "#{schema_name} should have the same top level fields as the JSON schema" do
      ast = GraphQL.parse_file(path)
      visitor = TopLevelFieldsVisitor.new(ast)
      visitor.visit

      json_schema = JSON.load_file(Rails.root.join("content_schemas/dist/formats/#{schema_name}/frontend/schema.json"))
      top_level_json_schema_fields = json_schema.fetch("properties").keys.to_set
      details_json_schema_fields = (json_schema.dig("definitions", "details", "properties") || {}).keys.to_set

      expect(visitor.top_level_graphql_query_fields).to eq(top_level_json_schema_fields)
      expect(visitor.details_graphql_query_fields).to eq(details_json_schema_fields)
    end
  end
end
