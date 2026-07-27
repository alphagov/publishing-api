# Breadth-first link expansion.
#
# Builds the `links_with_content` tree using the two batch SQL queries shared
# with the GraphQL API (Queries::LinkedToEditions / ReverseLinkedToEditions).
# It walks the link graph one level at a time, issuing a small fixed number of
# queries per level (O(depth)) rather than one query per node (O(nodes)).
#
# See docs/link-expansion.md and the design notes in
# docs/arch/adr-014-batch-link-expansion-and-dependency-resolution.md for the
# tricky bits.
class LinkExpansion
  EditionAndContentId = Data.define(:id, :content_id)
  Node = Data.define(:content_id, :link_type, :link_types_path, :excluded_content_ids, :links, :terminal)
  NodeAndLinkTypes = Data.define(:node, :direct_types, :reverse_types)

  def self.by_edition(edition, with_drafts: false)
    new(edition: edition, content_id: edition.content_id, locale: edition.locale, with_drafts:)
  end

  def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    new(edition: nil, content_id:, locale:, with_drafts:)
  end

  def initialize(edition: nil, content_id: nil, locale: nil, with_drafts: false)
    @edition = edition
    @content_id = content_id
    @locale = locale
    @with_drafts = with_drafts
    @forward_query = Queries::LinkedToEditions.new(locale:, with_drafts:)
    @reverse_query = Queries::ReverseLinkedToEditions.new(locale:, with_drafts:)
    @root_edition_resolver = LinkExpansion::RootEditionResolver.new(edition:, content_id:, locale:, with_drafts:)
    @rules = ExpansionRules
  end

  def links_with_content
    root_links = {}
    level_one_nodes = expand_root(root_links)
    LinkExpansion::AutoReverseLinker.new(root_edition:, with_drafts:).apply(level_one_nodes)

    frontier = level_one_nodes.reject(&:terminal)
    frontier = expand_level(frontier) until frontier.empty?

    root_links
  end

private

  attr_reader :edition, :content_id, :locale, :with_drafts, :forward_query, :reverse_query, :root_edition_resolver, :rules

  def expand_root(root_links)
    root_ids = EditionAndContentId.new(root_edition_id, content_id)

    reverse_types = rules.reverse_links
    direct_types = discover_root_direct_link_types

    forward_input = direct_types.map { |type| [root_ids, type] }
    reverse_input = reverse_input_for(root_ids, reverse_types)

    forward_results = forward_query.call(forward_input)
    reverse_results = reverse_query.call(reverse_input)

    next_frontier = []

    root = Node.new(
      content_id:,
      link_type: nil,
      link_types_path: [],
      excluded_content_ids: [],
      links: root_links,
      terminal: false,
    )

    # Root key order: reverse links, then direct links. Edition links are
    # followed at the root, so reverse attachment here keeps edition-sourced rows.
    attach_reverse(root, reverse_types, reverse_results, next_frontier, drop_edition_links: false)
    attach_direct(root, direct_types, forward_results, next_frontier)

    next_frontier
  end

  # The batch SQL needs explicit link types - for the root edition we expand all link types,
  # so we need to query the DB for all link types from the root edition / content id.
  def discover_root_direct_link_types
    scope = Link.where(link_set_content_id: content_id)
    scope = scope.or(Link.where(edition_id: root_edition_id)) if root_edition_id
    scope.distinct.order(:link_type).pluck(:link_type)
  end

  def expand_level(frontier)
    forward_input = []
    reverse_input = []

    nodes_and_link_types = frontier.map do |node|
      direct_types = rules.link_expansion.allowed_direct_link_types(node.link_types_path)
      reverse_types = rules.link_expansion.allowed_reverse_link_types(node.link_types_path)

      # edition_id is NULL for non-root nodes: edition links are only followed
      # at the root (we don't support nested edition links).
      child_ids = EditionAndContentId.new(nil, node.content_id)
      direct_types.each { |type| forward_input << [child_ids, type.to_s] }
      reverse_input.concat(reverse_input_for(child_ids, reverse_types))

      NodeAndLinkTypes.new(node:, direct_types:, reverse_types:)
    end

    forward_results = forward_query.call(forward_input)
    reverse_results = reverse_query.call(reverse_input)

    next_frontier = []
    nodes_and_link_types.each do |node_and_types|
      node = node_and_types.node
      # Child key order: direct links, then reverse links.
      # Edition links are not followed below root level.
      attach_direct(node, node_and_types.direct_types, forward_results, next_frontier)
      attach_reverse(node, node_and_types.reverse_types, reverse_results, next_frontier, drop_edition_links: true)
    end

    next_frontier
  end

  def attach_direct(parent, direct_types, forward_results, next_frontier)
    direct_types.each do |type|
      editions = forward_results.fetch([parent.content_id, type.to_s], [])
      attach(parent, next_frontier, type.to_sym, editions)
    end
  end

  def attach_reverse(parent, reverse_types, reverse_results, next_frontier, drop_edition_links:)
    reverse_types.each do |reverse_type|
      editions = reverse_editions(reverse_results, parent.content_id, reverse_type)
      attach(parent, next_frontier, reverse_type, editions, drop_edition_links:)
    end
  end

  # A reverse link type can fan out to several direct query types
  # (e.g. :role_appointments => [:person, :role])
  # Emit one input row per direct type, in that order.
  def reverse_input_for(ids, reverse_types)
    reverse_types.flat_map do |reverse_type|
      rules.reverse_to_direct_link_type(reverse_type).map { |direct| [ids, direct.to_s] }
    end
  end

  # Gather and re-key the reverse results for one reverse link type, the
  # result-side counterpart of reverse_input_for.
  def reverse_editions(reverse_results, source_content_id, reverse_type)
    rules.reverse_to_direct_link_type(reverse_type).flat_map do |direct|
      reverse_results.fetch([source_content_id, direct.to_s], [])
    end
  end

  # Attach the surviving editions for `link_type` into the parent's `links` hash
  # and push a frontier node for each. Non-terminal nodes have their own links
  # expanded at the next level; terminal (edition-link-sourced, root-level) nodes
  # are pushed only so AutoReverseLinker can decorate them - the caller drops
  # them from the frontier.
  def attach(parent, next_frontier, link_type, editions, drop_edition_links: false)
    survivors = survivors_for(editions, parent.excluded_content_ids, drop_edition_links:)
    return if survivors.empty?

    survivors_with_links = survivors.map { |edition| [edition, {}] }

    survivors_with_links.each do |edition, child_links|
      next_frontier << Node.new(
        content_id: edition.content_id,
        link_type:,
        link_types_path: parent.link_types_path + [link_type],
        excluded_content_ids: parent.excluded_content_ids + [edition.content_id],
        links: child_links,
        terminal: edition_link_sourced?(edition),
      )
    end

    parent.links[link_type] = survivors_with_links.map do |edition, child_links|
      expand_fields(edition, link_type).merge(links: child_links)
    end
  end

  def survivors_for(editions, excluded_content_ids, drop_edition_links:)
    editions = editions.reject { |edition| edition_link_sourced?(edition) } if drop_edition_links
    editions.reject { |edition| excluded_content_ids.include?(edition.content_id) }
  end

  def edition_link_sourced?(edition)
    edition.link_source == "edition"
  end

  def expand_fields(edition, link_type)
    rules.expand_fields(LinkExpansion::EditionHash.from(edition), link_type:, draft: with_drafts)
  end

  def root_edition
    root_edition_resolver.edition
  end

  def root_edition_id
    root_edition_resolver.id
  end
end
