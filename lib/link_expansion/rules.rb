module LinkExpansion::Rules
  extend self

  module RecurringLinks
    refine Symbol do
      def recurring
        [self]
      end
    end
  end

  using RecurringLinks

  MULTI_LEVEL_LINK_PATHS = [
    [:associated_taxons.recurring],
    [:child_taxons, :associated_taxons.recurring],
    [:child_taxons.recurring],
    [:parent.recurring],
    [:parent_taxons.recurring],
    [:taxons, :parent_taxons.recurring],
    [:ordered_related_items, :mainstream_browse_pages, :parent.recurring],
    [:ordered_related_items_overrides, :taxons]
  ].freeze

  REVERSE_LINKS = {
    parent: :children,
    documents: :document_collections,
    working_groups: :policies,
    parent_taxons: :child_taxons,
  }.freeze

  DEFAULT_FIELDS = [
    :analytics_identifier,
    :api_path,
    :base_path,
    :content_id,
    :description,
    :document_type,
    :locale,
    :public_updated_at,
    :schema_name,
    :title,
    :withdrawn,
  ].freeze

  DEFAULT_FIELDS_WITH_DETAILS = (DEFAULT_FIELDS + [:details]).freeze

  CUSTOM_EXPANSION_FIELDS = [
    { document_type: :redirect,                   fields: [] },
    { document_type: :gone,                       fields: [] },
    { document_type: :topical_event,              fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :placeholder_topical_event,  fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :organisation,               fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :placeholder_organisation,   fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :taxon,                      fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :need,                       fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :finder, link_type: :finder, fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :travel_advice,              fields: DEFAULT_FIELDS + [[:details, :country], [:details, :change_description]] },
    { document_type: :world_location,             fields: [:content_id, :title, :schema_name, :locale, :analytics_identifier] },
  ].freeze

  def root_reverse_links
    REVERSE_LINKS.values
  end

  def reverse_link_type(link_type)
    REVERSE_LINKS[link_type.to_sym]
  end

  def un_reverse_link_type(link_type)
    REVERSE_LINKS.key(link_type.to_sym)
  end

  def is_reverse_link_type?(link_type)
    un_reverse_link_type(link_type).present?
  end

  def un_reverse_link_types(link_types)
    return unless link_types
    link_types.map { |type| un_reverse_link_type(type) }.compact
  end

  def reverse_link_types_hash(link_types)
    link_types.each_with_object({}) do |(link_type, content_ids), memo|
      reversed = reverse_link_type(link_type)
      memo[reversed] = content_ids if reversed
    end
  end

  def next_link_expansion_link_types(link_types_path)
    next_link_type(link_types_path, reverse: false)
  end

  def next_dependency_resolution_link_types(link_types_path)
    next_link_type(link_types_path, reverse: true)
  end

  def find_custom_expansion_fields(document_type, options = {})
    should_check_link_type = options.include?(:link_type)
    link_type = options[:link_type].try(:to_sym)

    condition = CUSTOM_EXPANSION_FIELDS.find do |cond|
      next if should_check_link_type && cond.fetch(:link_type, link_type) != link_type
      cond[:document_type] == document_type.to_sym
    end
    condition[:fields] if condition
  end

  def expansion_fields(document_type, link_type = nil)
    find_custom_expansion_fields(document_type, link_type: link_type) ||
      DEFAULT_FIELDS
  end

  def potential_expansion_fields(document_type)
    (find_custom_expansion_fields(document_type) || DEFAULT_FIELDS).map do |field|
      Array(field).first
    end
  end

  def expand_fields(edition_hash, link_type)
    expansion_fields(edition_hash[:document_type], link_type).each_with_object({}) do |field, expanded|
      field = Array(field)
      expanded[field.last] = edition_hash.dig(*field)
    end
  end

  def valid_link_expansion_link_types_path?(link_types_path)
    valid_paths = multi_level_link_paths(
      length: link_types_path.length,
      reverse: false,
    )
    valid_paths.include?(link_types_path)
    valid_paths.any? { |path| path[0...link_types_path.length] == link_types_path }
  end

  def valid_dependency_resolution_link_types_path?(link_types_path)
    valid_paths = multi_level_link_paths(
      length: link_types_path.length,
      reverse: true,
    )
    valid_paths.any? { |path| path[0...link_types_path.length] == link_types_path }
  end

private

  def next_link_type(link_types_path, reverse:)
    raise "Can't operate on an empty link_types_path" if link_types_path.empty?
    extra_item_1 = multi_level_link_paths(length: link_types_path.length + 1, reverse: reverse)
    extra_item_2 = multi_level_link_paths(length: link_types_path.length + 2, reverse: reverse)
    (extra_item_1 + extra_item_2).uniq
      .map { |path| next_link_type_in_path(link_types_path, path, reverse) }
      .compact
      .uniq
  end

  def multi_level_link_paths(length: 1, reverse: false)
    paths = MULTI_LEVEL_LINK_PATHS.map do |path|
      recurring = path.count { |a| a.is_a?(Array) }
      raise "Only 1 recurring item supported" if recurring > 1
      non_recurring = path.count - recurring
      cycles = [1, length - non_recurring].max
      path.flat_map { |item| item.is_a?(Array) ? item.cycle(cycles).to_a : item }
    end

    reverse ? paths.map(&:reverse) : paths
  end

  def next_link_type_in_path(current_path, path_to_check, reverse = false)
    if !reverse
      match = path_to_check[0...current_path.length] == current_path
      path_to_check[current_path.length] if match
    else
      range = path_to_check.length - current_path.length
      # find an index of where the current path matches the path_to_check
      matching_index = (0..range).find do |index|
        check_length = index + current_path.length
        path_to_check[index...check_length] == current_path
      end
      path_to_check[matching_index + current_path.length] if matching_index
    end
  end
end
