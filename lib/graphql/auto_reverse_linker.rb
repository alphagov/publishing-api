class Graphql::AutoReverseLinker
  DEFAULT_LINK_FIELDS = %w[
    api_url
    web_url
  ].freeze

  def initialize(edition)
    @edition = edition
  end

  def insert_links(content_item)
    return content_item if content_item["links"].blank?

    content_item.merge({ "links" => update_links(content_item["links"]) })
  end

private

  def update_links(content_item_links)
    content_item_links.each_with_object({}) do |(link_type, links_array), updated_links|
      unless needs_auto_reverse_link?(link_type)
        updated_links[link_type] = links_array
        next
      end

      auto_reverse_types = ExpansionRules.reverse_to_direct_link_type(link_type).map(&:to_s)

      updated_links[link_type] = links_array.map do |link|
        link.merge({
          "links" => with_auto_reverse_links(
            link["links"] || {},
            auto_reverse_types,
          ),
        })
      end
    end
  end

  def with_auto_reverse_links(nested_links, auto_reverse_types)
    (nested_links.keys + auto_reverse_types).sort.index_with do |link_type|
      if auto_reverse_types.include?(link_type)
        [build_auto_link(link_type)]
      else
        nested_links[link_type]
      end
    end
  end

  def build_auto_link(link_type)
    ExpansionRules.expand_fields(
      LinkExpansion::EditionHash.from(@edition),
      link_type: link_type,
      draft: false,
    )
      .stringify_keys
      .merge(DEFAULT_LINK_FIELDS.each_with_object({}) { _2[_1] = @edition.send(_1) })
      .merge({ "links" => {} })
  end

  # NOTE: part of this rule is copied from LinkExpansion#should_link?
  def needs_auto_reverse_link?(link_type)
    is_reverse_link_type?(link_type) &&
      (Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(link_type) ||
        @edition.state != "unpublished")
  end

  def is_reverse_link_type?(link_type)
    # if "role_appointments" is a top-level link, it's not the reverse kind ':|
    return false if link_type == "role_appointments"

    ExpansionRules.is_reverse_link_type?(link_type)
  end
end
