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
    link_reference.links_by_link_type(
      content_id: content_id,
      parent_is_edition: parent_is_edition?,
      locale: locale,
      with_drafts: with_drafts?,
      link_types_path: link_types_path,
      parent_content_ids: parent_content_ids,
    )
  end

  def with_drafts?
    link_graph.with_drafts
  end

  def locale
    parent_node ? parent_node.locale : link_graph.root_locale
  end

  def content_id
    parent_node ? parent_node.content_id : link_graph.root_content_id
  end

  def link_types_path
    parent_node ? parent_node.link_types_path : []
  end

  def parent_content_ids
    parent_node ? parent_node.parent_content_ids : []
  end

  def parent_is_edition?
    parent_node ? parent_node.edition_id.present? : false
  end

  def link_reference
    link_graph.link_reference
  end

  def valid_link_nodes(link_type, links)
    links = links.map do |link|
      # as we are taking links from both editions (which come as [content_id,
      # locale, edition_id]) and link sets (which comes as a content_id)
      link_content_id, link_locale, edition_id = link.is_a?(Array) ? link : [link, nil, nil]
      LinkGraph::Node.new(
        content_id: link_content_id,
        locale: link_locale,
        edition_id: edition_id,
        link_type: link_type,
        parent: parent_node,
        link_graph: link_graph,
      )
    end
    links.select { |node| link_reference.valid_link_node?(node) }
  end
end
