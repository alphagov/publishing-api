#
# This is the core class of Link Expansion which is a complicated concept
# in the Publishing API
#
# The concept is documented in /doc/link-expansion.md
#
class LinkExpansion
  def self.by_edition(edition, with_drafts: false)
    self.new(edition: edition, with_drafts: with_drafts)
  end

  def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    self.new(content_id: content_id, locale: locale, with_drafts: with_drafts)
  end

  def initialize(options)
    @options = options
    @with_drafts = options.fetch(:with_drafts)
  end

  def links_with_content
    populate_links(link_graph.links)
  end

  def link_graph
    @link_graph ||= LinkGraph.new(
      root_content_id: content_id,
      root_locale: locale,
      with_drafts: with_drafts,
      link_reference: LinkReference.new
    )
  end

private

  attr_reader :options, :with_drafts

  def edition
    @edition ||= options[:edition]
  end

  def content_id
    edition ? edition.content_id : options.fetch(:content_id)
  end

  def locale
    edition ? edition.locale : options.fetch(:locale)
  end

  def content_cache
    @content_cache ||= ContentCache.new(
      locale: locale,
      preload_editions: edition ? [edition] : [],
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
    edition_hash = content_cache.find(node.content_id)
    return if !edition_hash || !should_link?(node.link_type, edition_hash)
    rules.expand_fields(edition_hash, node.link_type).tap do |expanded|
      links = populate_links(node.links)
      auto_reverse = auto_reverse_link(node)
      expanded.merge!(links: (auto_reverse || {}).merge(links))
    end
  end

  def auto_reverse_link(node)
    if node.link_types_path.length != 1 || !rules.is_reverse_link_type?(node.link_types_path.first)
      return {}
    end
    edition_hash = content_cache.find(content_id)
    return if !edition_hash || !should_link?(node.link_type, edition_hash)
    un_reverse_link_type = rules.un_reverse_link_type(node.link_types_path.first)
    { un_reverse_link_type => [rules.expand_fields(edition_hash, un_reverse_link_type).merge(links: {})] }
  end

  def should_link?(link_type, edition_hash)
    # Only specific link types can be withdrawn
    # FIXME: We're leaking publishing app domain knowledge into the API here.
    # The agreed approach will be to allow any withdrawn links to appear but
    # this requires we assess impact on the rendering applications first.
    %i(children parent related_statistical_data_sets).include?(link_type) ||
      edition_hash[:state] != "unpublished"
  end

  def rules
    Rules
  end
end
