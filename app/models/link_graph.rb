class LinkGraph
  attr_reader :root_content_id, :with_drafts, :locales, :link_reference

  def initialize(root_content_id, with_drafts, locales, link_reference)
    @root_content_id = root_content_id
    @with_drafts = with_drafts
    @locales = locales
    @link_reference = link_reference
  end

  def links
    @links ||= NodeCollectionFactory.new(self).collection
  end

  def links_content_ids
    links.flat_map { |link| [link.content_id] + link.links_content_ids }.uniq
  end

  def to_s
    "LinkGraph(#{root_content_id})"
  end

  def inspect
    "LinkGraph(content_id: #{root_content_id}, links: #{links.map(&:content_id)})"
  end

  def to_h
    links.group_by(&:link_type)
      .each_with_object({}) do |(link_type, links), memo|
        memo[link_type] = links.map(&:to_h)
      end
  end
end
