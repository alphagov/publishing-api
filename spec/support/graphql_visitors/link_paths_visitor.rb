class LinkPathsVisitor < GraphQL::Language::StaticVisitor
  attr_reader :link_paths

  def initialize(document)
    super

    @current_path = []
    @link_paths = Set.new
  end

  def on_field(node, parent)
    if parent.is_a?(GraphQL::Language::Nodes::Field) && parent.name == "links"
      @current_path << node.name.to_sym

      if node.selections.none? { _1.name == "links" }
        link_paths << @current_path.dup
      else
        super
      end

      @current_path.pop
    else
      super
    end
  end
end

