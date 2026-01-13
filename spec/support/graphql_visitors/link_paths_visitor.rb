class LinkPathsVisitor < GraphQL::Language::StaticVisitor
  attr_reader :full_link_paths
  attr_reader :selections_by_link_path

  def initialize(document)
    super

    @current_path = []
    @full_link_paths = Set.new
    @fragment_definitions = []
    @selections_by_link_path = {}
  end

  def on_document(node, _parent)
    @fragment_definitions = node.definitions.select { _1.is_a? GraphQL::Language::Nodes::FragmentDefinition }
    super
  end

  def on_field(node, parent)
    if parent.is_a?(GraphQL::Language::Nodes::Field) && parent.name == "links"
      @current_path << node.name.to_sym
      path = @current_path.dup

      selections_by_link_path[path] = expand_fragment_selections(node.selections)
                                        .map { _1.alias || _1.name }
                                        .map(&:to_sym)
      full_link_paths << path if node.selections.none? { _1.name == "links" }
      super

      @current_path.pop
    else
      super
    end
  end

  private

  def expand_fragment_selections(selections)
    selections.flat_map do |selection|
      if selection.is_a?(GraphQL::Language::Nodes::FragmentSpread)
        fragment_definition = @fragment_definitions.find { |f| f.name == selection.name }
        raise "No fragment definition found for #{selection.name}" if fragment_definition.nil?

        expand_fragment_selections(fragment_definition.selections)
      else
        [selection]
      end
    end
  end
end
