# This class represents a link in a link graph.
#
# It may be a child of a parent link node
class LinkGraph::Node
  attr_reader :content_id, :locale, :edition_id, :link_type, :parent, :link_graph

  def initialize(
    content_id:,
    locale:,
    edition_id:,
    link_type:,
    parent:,
    link_graph:,
    has_own_links: nil,
    is_linked_to: nil
  )
    @content_id = content_id
    @locale = locale
    @edition_id = edition_id
    @link_type = link_type
    @parent = parent
    @link_graph = link_graph
    @has_own_links = has_own_links
    @is_linked_to = is_linked_to
  end

  def links
    @links ||= begin
      # If we know there aren't links we can save some execution by setting
      # this directly to an empty array
      if might_have_links?
        LinkGraph::NodeCollectionFactory.new(link_graph, self).collection
      else
        []
      end
    end
  end

  # An array of link_type to indicate the path from the root to this node.
  # For a link that is a child of a parent_taxons this could be
  # [parent_taxons, parent_taxons] for instance
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

  def might_have_own_links?
    has_own_links != false
  end

  def might_be_linked_to?
    is_linked_to != false
  end

  def might_have_links?
    might_have_own_links? || might_be_linked_to?
  end

private

  attr_reader :has_own_links, :is_linked_to
end
