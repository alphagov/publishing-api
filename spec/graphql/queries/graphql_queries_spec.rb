class TopLevelFieldsVisitor < GraphQL::Language::StaticVisitor
  attr_reader :top_level_graphql_query_fields, :details_graphql_query_fields

  def on_field(node, _parent)
    # Note: not calling super because we don't need to look at subfields for the top level
    return unless node.name == "edition"

    node.selections => [GraphQL::Language::Nodes::InlineFragment => inline_fragment]
    fields = inline_fragment.selections

    @top_level_graphql_query_fields = fields.map(&:name).to_set
    @details_graphql_query_fields = fields.find { _1.name == "details" }&.selections&.map(&:name)&.to_set
  end
end

class ExpandedLinksVisitor < GraphQL::Language::StaticVisitor
  def initialize(document)
    super

    @path = []
  end

  def on_field(node, parent)
    if parent.is_a?(GraphQL::Language::Nodes::Field) && parent.name == "links"
      @path << node.name
      pp(@path)
      super
      @path.pop
    else
      super
    end
  end
end

RSpec.describe "GraphQL queries" do
  Dir[Rails.root.join("app/graphql/queries/*.graphql")].each do |path|
    /(?<schema_name>[^\/]+)[.]graphql\Z/ =~ path

    context schema_name do
      it "should have the same top level fields as the JSON schema" do
        ast = GraphQL.parse_file(path)
        visitor = TopLevelFieldsVisitor.new(ast)
        visitor.visit

        json_schema = JSON.load_file(Rails.root.join("content_schemas/dist/formats/#{schema_name}/frontend/schema.json"))
        top_level_json_schema_fields = json_schema.fetch("properties").keys.to_set
        details_json_schema_fields = (json_schema.dig("definitions", "details", "properties") || {}).keys.to_set

        expect(visitor.top_level_graphql_query_fields).to eq(top_level_json_schema_fields)
        expect(visitor.details_graphql_query_fields).to eq(details_json_schema_fields)
      end

      it "should expand links according to the expansion rules" do
        ast = GraphQL.parse_file(path)
        visitor = ExpandedLinksVisitor.new(ast)
        visitor.visit
      end
    end
  end
end
