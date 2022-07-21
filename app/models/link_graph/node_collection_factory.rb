class LinkGraph::NodeCollectionFactory
  def initialize(link_graph, parent_node = nil)
    @link_graph = link_graph
    @parent_node = parent_node
  end

  def collection
    links_by_link_type.flat_map do |link_type, links|
      valid_link_nodes(link_type, links)
    end
  end

private

  attr_reader :link_graph, :with_drafts, :parent_node

  def links_by_link_type
    # We don't support nested edition links
    return [] if parent_is_edition?

    if root?
      link_reference.root_links_by_link_type(
        content_id: link_graph.root_content_id,
        locale: link_graph.root_locale,
        with_drafts: link_graph.with_drafts,
      )
    else
      link_reference.child_links_by_link_type(
        content_id: parent_node.content_id,
        link_types_path: parent_node.link_types_path,
        parent_content_ids: parent_node.parent_content_ids,
        might_have_own_links: parent_node.might_have_own_links?,
        might_be_linked_to: parent_node.might_be_linked_to?,
      )
    end
  end

  def root?
    parent_node.nil?
  end

  def parent_is_edition?
    parent_node ? parent_node.edition_id.present? : false
  end

  def link_reference
    link_graph.link_reference
  end

  def valid_link_nodes(link_type, links)
    links = links.map do |link|
      LinkGraph::Node.new(
        content_id: link[:content_id],
        locale: link[:locale],
        edition_id: link[:edition_id],
        link_type: link_type,
        parent: parent_node,
        link_graph: link_graph,
        has_own_links: link[:has_own_links],
        is_linked_to: link[:is_linked_to],
      )
    end

    links.select { |node| link_reference.valid_link_node?(node) }
  end
end
