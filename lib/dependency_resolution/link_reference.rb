class DependencyResolution::LinkReference
  def valid_link_node?(node)
    return true if node.link_types_path.length == 1
    return true if node.links.present?

    rules.dependency_resolution.valid_link_types_path?(node.link_types_path)
  end

  def root_links_by_link_type(content_id:, locale:, with_drafts: false)
    direct = linked_to(content_id)
    reverse = own_links(content_id, rules.reverse_links)
    puts "direct"
    puts direct.inspect
    puts "reverse"
    puts reverse.inspect

    links = reverse.merge!(direct)

    edition = edition_links(content_id, locale, with_drafts)

    merge_links(links, edition)
  end

  def child_links_by_link_type(
    content_id:,
    link_types_path:,
    locale:,
    parent_content_ids: [],
    might_have_own_links: true,
    might_be_linked_to: true,
    with_drafts: false
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

    edition = edition_links(content_id, locale, with_drafts, parent_content_ids)

    merge_links(links, edition)
  end

private

  def merge_links(links1, links2)
    links1.merge(links2) do |_key, link1, link2|
      content_ids = link1.pluck(:content_id) + link2.pluck(:content_id)

      output = content_ids.uniq.map do |content_id|
        link1_values = link1.select { |link| link[:content_id] == content_id }.first
        link2_values = link2.select { |link| link[:content_id] == content_id }.first
        puts "LINK1"
        puts link1_values.inspect
        puts "LINK2"
        puts link2_values.inspect

        if link1_values && link2_values
          {
            content_id:,
            has_own_links: link1_values[:has_own_links] == true || link2_values[:has_own_links] == true,
            is_linked_to: link1_values[:is_linked_to] == true || link2_values[:is_linked_to] == true,
          }
        elsif link1_values
          link1_values
        elsif link2_values
          link2_values
        end
      end

      puts "HERE"
      puts output.inspect
      output
    end
  end

  def child_own_links(content_id, link_types_path = [], parent_content_ids = [])
    allowed_link_types = rules.dependency_resolution
      .allowed_reverse_link_types(link_types_path)

    return {} if allowed_link_types.empty?

    own_links(content_id, allowed_link_types, link_types_path, parent_content_ids)
  end

  def own_links(content_id, allowed_link_types = nil, link_types_path = [], parent_content_ids = [])
    next_allowed_link_types_from = rules.dependency_resolution
      .next_allowed_reverse_link_types(allowed_link_types, link_types_path, reverse_to_direct: true)
    next_allowed_link_types_to = rules.dependency_resolution
      .next_allowed_direct_link_types(allowed_link_types, link_types_path, reverse_to_direct: true)

    links = Queries::Links.from(
      content_id,
      allowed_link_types: rules.reverse_to_direct_link_types(allowed_link_types),
      parent_content_ids:,
      next_allowed_link_types_from:,
      next_allowed_link_types_to:,
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
      .next_allowed_reverse_link_types(allowed_link_types, link_types_path, reverse_to_direct: true)
    next_allowed_link_types_to = rules.dependency_resolution
      .next_allowed_direct_link_types(allowed_link_types, link_types_path, reverse_to_direct: true)

    Queries::Links.to(
      content_id,
      allowed_link_types:,
      parent_content_ids:,
      next_allowed_link_types_from:,
      next_allowed_link_types_to:,
    )
  end

  def edition_links(content_id, locale, with_drafts, parent_content_ids = [])
    link_types_path = []

    to_links = Queries::EditionLinks.to(
      content_id,
      locale:,
      with_drafts:,
      allowed_link_types: nil,
      next_allowed_link_types_from: rules.dependency_resolution.next_allowed_reverse_link_types(nil, link_types_path, reverse_to_direct: true),
      next_allowed_link_types_to: rules.dependency_resolution.next_allowed_direct_link_types(nil, link_types_path, reverse_to_direct: true),
      parent_content_ids:,
    )

    puts to_links.inspect

    from_links = Queries::EditionLinks.from(
      content_id,
      locale:,
      with_drafts:,
      allowed_link_types: rules.reverse_to_direct_link_types(rules.reverse_links),
      next_allowed_link_types_from: rules.dependency_resolution.next_allowed_reverse_link_types(nil, link_types_path, reverse_to_direct: true),
      next_allowed_link_types_to: rules.dependency_resolution.next_allowed_direct_link_types(nil, link_types_path, reverse_to_direct: true),
      parent_content_ids:,
    )

    puts from_links.inspect

    from_links = rules.reverse_link_types_hash(from_links)

    from_links.merge(to_links)
  end

  def rules
    ExpansionRules
  end
end
