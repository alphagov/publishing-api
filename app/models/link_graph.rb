# This class is used to represent the graph of links for an edition.
# It is used in [link expansion](../doc/link-expansion.md) and
# [dependency resolution](../doc/depedency-resolution.md)
class LinkGraph
  attr_reader :root_content_id, :root_locale, :with_drafts, :link_reference

  # link_reference is an object that can be queried to determine the links
  # for given inputs. It is the source of information for representing this
  # graph.
  def initialize(
    root_content_id:,
    root_locale:,
    with_drafts: false,
    link_reference:
  )
    @root_content_id = root_content_id
    @root_locale = root_locale
    @with_drafts = with_drafts
    @link_reference = link_reference
  end

  def links
    @links ||= NodeCollectionFactory.new(self).collection
  end

  def links_content_ids
    links.flat_map { |link| [link.content_id] + link.links_content_ids }.uniq
  end

  def links_with_priority
    links.flat_map { |link| [{ content_id: link.content_id, priority: link.link_reference.priority(link) } + links.links_with_priority] }
  end

  def to_s
    "LinkGraph(#{root_content_id}, #{root_locale})"
  end

  def inspect
    "LinkGraph(content_id: #{root_content_id}, locale: #{root_locale}, "\
    "with_drafts: #{with_drafts}, links: #{links.map(&:content_id)})"
  end

  def to_h
    links.group_by(&:link_type)
      .each_with_object({}) do |(link_type, links), memo|
        memo[link_type] = links.map(&:to_h)
      end
  end
end
