#
# This is the core class of Link Expansion which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/link-expansion.md
#
class LinkExpansion
  def self.by_edition(edition, with_drafts: false)
    new(edition:, with_drafts:)
  end

  def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    new(content_id:, locale:, with_drafts:)
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
      with_drafts:,
      link_reference: LinkReference.new,
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
      locale:,
      preload_editions: edition ? [edition] : [],
      preload_content_ids: (link_graph.links_content_ids + [content_id]).uniq,
      with_drafts:,
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

    expanded = rules.expand_fields(
      edition_hash,
      link_type: node.link_type,
      draft: with_drafts,
    )

    links = auto_reverse_link(node).merge(populate_links(node.links))
    expanded.merge(links:)
  end

  def auto_reverse_link(node)
    if node.link_types_path.length != 1 || !rules.is_reverse_link_type?(node.link_types_path.first)
      return {}
    end

    reverse_link_type = node.link_types_path.first
    direct_link_type = rules.member_expansion_direct_link_type(reverse_link_type)

    if direct_link_type
      return reverse_link_member_links(node.content_id, direct_link_type)
    end

    edition_hash = content_cache.find(content_id)
    return {} if !edition_hash || !should_link?(node.link_type, edition_hash)

    rules
      .reverse_to_direct_link_type(reverse_link_type)
      .each_with_object({}) do |reverse_to_direct_link_type, memo|
        expanded = rules.expand_fields(
          edition_hash,
          link_type: reverse_to_direct_link_type,
          draft: with_drafts,
        )
        memo[reverse_to_direct_link_type] = [expanded.merge(links: {})]
      end
  end

  def reverse_link_member_links(source_content_id, direct_link_type)
    member_links = Queries::Links.from(
      source_content_id,
      allowed_link_types: [direct_link_type],
    )[direct_link_type] || []

    members = member_links.filter_map do |link|
      edition_hash = content_cache.find(link[:content_id])
      next unless edition_hash && should_link?(direct_link_type, edition_hash)

      rules.expand_fields(
        edition_hash,
        link_type: direct_link_type,
        draft: with_drafts,
      ).merge(links: {})
    end

    return {} if members.empty?

    { direct_link_type => members }
  end

  def should_link?(link_type, edition_hash)
    # Only specific link types can be withdrawn
    # FIXME: We're leaking publishing app domain knowledge into the API here.
    # The agreed approach will be to allow any withdrawn links to appear but
    # this requires we assess impact on the rendering applications first.
    Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(link_type.to_s) ||
      edition_hash[:state] != "unpublished"
  end

  def rules
    ExpansionRules
  end
end
