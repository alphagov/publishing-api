class LinkGraph::Node
  attr_reader :content_id, :locale, :edition_id, :link_type, :parent, :link_graph

  def initialize(
    content_id:,
    locale:,
    edition_id:,
    link_type:,
    parent:,
    link_graph:
  )
    @content_id = content_id
    @locale = locale
    @edition_id = edition_id
    @link_type = link_type
    @parent = parent
    @link_graph = link_graph
  end

  def links
    @links ||= LinkGraph::NodeCollectionFactory.new(link_graph, self).collection
  end

  def link_types_path
    parent ? parent.link_types_path + [link_type] : [link_type]
  end

  def parent_content_ids
    parents.map(&:content_id)
  end

  def parents
    parent ? parent.parents + [parent] : []
  end

  def links_content_ids
    links.flat_map { |link| [link.content_id] + link.links_content_ids }.uniq
  end

  def to_s
    "LinkGraph::Node(#{content_id}, #{locale ? locale : 'nil'})"
  end

  def inspect
    "LinkGraph::Node(content_id: #{content_id}, locale: #{locale}, "\
      "edition_id: #{edition_id}, link_type: #{link_type}, "\
      "links: #{links.map(&:content_id)})"
  end

  def ==(another_node)
    self.to_h == another_node.to_h
  end

  def to_h
    children = links.group_by(&:link_type)
      .each_with_object({}) do |(link_type, links), memo|
        memo[link_type] = links.map(&:to_h)
      end

    {
      content_id: content_id,
      links: children,
    }
  end
end
