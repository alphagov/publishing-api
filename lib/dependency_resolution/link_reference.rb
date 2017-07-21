class DependencyResolution::LinkReference
  def valid_link_node?(node)
    return true if node.link_types_path.length == 1
    return true if node.links.present?

    rules.dependency_resolution.valid_link_types_path?(node.link_types_path)
  end

  def root_links_by_link_type(content_id:, locale:, with_drafts: false)
    direct = linked_to(content_id)
    reverse = own_links(content_id, rules.reverse_links)
    edition = edition_links(content_id, locale, with_drafts)

    reverse.merge(direct).merge(edition) do |_key, link_1, link_2|
      link_1 + link_2
    end
  end

  def child_links_by_link_type(
    content_id:,
    link_types_path:,
    parent_content_ids: [],
    might_have_own_links: true,
    might_be_linked_to: true
  )
    links = {}

    if might_have_own_links
      own_links = child_own_links(content_id, link_types_path, parent_content_ids)
      links.merge!(own_links)
    end

    if might_be_linked_to
      linked_to = child_linked_to(content_id, link_types_path, parent_content_ids)
      links.merge!(linked_to)
    end

    links
  end

private

  def child_own_links(content_id, link_types_path = [], parent_content_ids = [])
    allowed_link_types = rules.dependency_resolution
      .allowed_reverse_link_types(link_types_path)

    return {} if allowed_link_types.empty?

    own_links(content_id, allowed_link_types, link_types_path, parent_content_ids)
  end

  def own_links(content_id, allowed_link_types = nil, link_types_path = [], parent_content_ids = [])
    next_allowed_link_types_from = rules.dependency_resolution
      .next_allowed_reverse_link_types(allowed_link_types, link_types_path, unreverse: true)
    next_allowed_link_types_to = rules.dependency_resolution
      .next_allowed_direct_link_types(allowed_link_types, link_types_path)

    links = Queries::Links.from(content_id,
      allowed_link_types: rules.unreverse_link_types(allowed_link_types),
      parent_content_ids: parent_content_ids,
      next_allowed_link_types_from: next_allowed_link_types_from,
      next_allowed_link_types_to: next_allowed_link_types_to,
    )

    rules.reverse_link_types_hash(links)
  end

  def child_linked_to(content_id, link_types_path = [], parent_content_ids = [])
    allowed_link_types = rules.dependency_resolution
      .allowed_direct_link_types(link_types_path)

    return {} if allowed_link_types.empty?

    linked_to(content_id, allowed_link_types, link_types_path, parent_content_ids)
  end

  def linked_to(content_id, allowed_link_types = nil, link_types_path = [], parent_content_ids = [])
    next_allowed_link_types_from = rules.dependency_resolution
      .next_allowed_reverse_link_types(allowed_link_types, link_types_path, unreverse: true)
    next_allowed_link_types_to = rules.dependency_resolution
      .next_allowed_direct_link_types(allowed_link_types, link_types_path)

    Queries::Links.to(content_id,
      allowed_link_types: allowed_link_types,
      parent_content_ids: parent_content_ids,
      next_allowed_link_types_from: next_allowed_link_types_from,
      next_allowed_link_types_to: next_allowed_link_types_to,
    )
  end

  def edition_links(content_id, locale, with_drafts)
    to_links = Queries::EditionLinks.to(content_id,
      locale: locale,
      with_drafts: with_drafts,
      allowed_link_types: nil,
    )

    from_links = Queries::EditionLinks.from(content_id,
      locale: locale,
      with_drafts: with_drafts,
      allowed_link_types: rules.unreverse_link_types(rules.reverse_links)
    )

    from_links = rules.reverse_link_types_hash(from_links)

    from_links.merge(to_links)
  end

  def rules
    ExpansionRules
  end
end
