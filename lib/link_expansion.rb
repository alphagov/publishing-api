class LinkExpansion
  attr_reader :content_id, :locale, :with_drafts

  def initialize(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    @content_id = content_id
    @locale = locale
    @with_drafts = with_drafts
  end

  def links_with_content
    populate_links(link_graph.links)
  end

  def link_graph
    @link_graph ||= LinkGraph.new(content_id, locale, with_drafts, LinkReference.new)
  end

private

  def content_cache
    @content_cache ||= ContentCache.new(
      locale: locale,
      preload_content_ids: (link_graph.links_content_ids + [content_id]).uniq,
      with_drafts: with_drafts,
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
    rules.expand_fields(edition).tap do |expanded|
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
    un_reverse_link_type = rules.un_reverse_link_type(node.link_types_path.first)
    { un_reverse_link_type => [rules.expand_fields(edition).merge(links: {})] }
  end

  def should_link?(link_type, edition)
    # Only specific link types can be withdrawn
    # FIXME: We're leaking publishing app domain knowledge into the API here.
    # The agreed approach will be to allow any withdrawn links to appear but
    # this requires we assess impact on the rendering applications first.
    %i(children parent related_statistical_data_sets).include?(link_type) ||
      edition.state != "unpublished"
  end

  def rules
    Rules
  end
end
