class LinkExpansion
  attr_reader :content_id, :with_drafts, :locale_fallback_order

  def initialize(content_id, with_drafts:, locale_fallback_order:)
    @content_id = content_id
    @with_drafts = with_drafts
    @locale_fallback_order = locale_fallback_order
  end

  def links_with_content
    populate_links(link_graph.links)
  end

  def link_graph
    @link_graph ||= LinkGraph.new(content_id, LinkReference.new)
  end

private

  def content_cache
    @content_cache ||= ContentCache.new(
      with_drafts: with_drafts,
      locale_fallback_order: locale_fallback_order,
      preload_content_ids: (link_graph.links_content_ids + [content_id]).uniq,
    )
  end

  def populate_links(links)
    links.each_with_object({}) do |link_node, memo|
      content = link_content(link_node)
      (memo[link_node.link_type] ||= []) << content if content
    end
  end

  def link_content(node)
    edition = content_cache.find(node.content_id)
    return if !edition || !should_link?(node.link_type, edition)
    content_item = ContentItem.new(edition)
    rules.expand_fields(content_item).tap do |expanded|
      links = populate_links(node.links)
      auto_reverse = auto_reverse_link(node)
      expanded.merge!(links: (auto_reverse || {}).merge(links))
    end
  end

  def auto_reverse_link(node)
    if node.link_types_path.length != 1 || !rules.is_reverse_link_type?(node.link_types_path.first)
      return {}
    end
    edition = content_cache.find(content_id)
    return if !edition || !should_link?(node.link_type, edition)
    content_item = ContentItem.new(edition)
    un_reverse_link_type = rules.un_reverse_link_type(node.link_types_path.first)
    { un_reverse_link_type => [rules.expand_fields(content_item).merge(links: {})] }
  end

  def should_link?(link_type, content_item)
    # Only specific link types can be withdrawn
    # FIXME: We're leaking publishing app domain knowledge into the API here.
    # The agreed approach will be to allow any withdrawn links to appear but
    # this requires we assess impact on the rendering applications first.
    %i(children parent related_statistical_data_sets).include?(link_type) ||
      content_item.state != "unpublished"
  end

  def rules
    Rules
  end
end
