class TopLevelFieldsVisitor < GraphQL::Language::StaticVisitor
  attr_reader :top_level_graphql_query_fields, :details_graphql_query_fields

  def on_field(node, _parent)
    # Because we're only looking at top level fields we don't need to call super to visit subfields
    return unless node.name == "edition"

    # => syntax will raise an error if the edition field doesn't use a single inline fragment
    node.selections => [GraphQL::Language::Nodes::InlineFragment => inline_fragment]
    fields = inline_fragment.selections

    details_field = fields.find { |field| field.alias == "details" || field.name == "details" }
    @top_level_graphql_query_fields = fields.map(&:name).uniq
    @details_graphql_query_fields = details_field&.selections&.map(&:name)&.uniq || []
  end
end
