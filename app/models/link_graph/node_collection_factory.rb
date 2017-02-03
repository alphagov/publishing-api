class LinkGraph::NodeCollectionFactory
  def initialize(link_graph, parent_node = nil)
    @link_graph = link_graph
    @parent_node = parent_node
  end

  def collection
    links_by_link_type.flat_map do |link_type, link_content_ids|
      valid_link_nodes(link_type, link_content_ids)
    end
  end

private

  attr_reader :link_graph, :parent_node

  def content_id
    parent_node ? parent_node.content_id : link_graph.root_content_id
  end

  def link_types_path
    parent_node ? parent_node.link_types_path : []
  end

  def parent_content_ids
    parent_node ? parent_node.parent_content_ids : []
  end

  def link_reference
    link_graph.link_reference
  end

  def links_by_link_type
    link_reference.links_by_link_type(
      content_id,
      link_types_path,
      parent_content_ids
    )
  end

  def valid_link_nodes(link_type, link_content_ids)
    links = link_content_ids.map do |link_content_id|
      LinkGraph::Node.new(link_content_id, link_type, parent_node, link_graph)
    end
    links.select { |node| link_reference.valid_link_node?(node) }
  end
end
