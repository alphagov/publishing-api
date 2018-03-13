module ExpansionRules
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
    [:parent_taxons.recurring, :root_taxon],
    [:taxons, :root_taxon],
    [:taxons, :parent_taxons.recurring],
    [:taxons, :parent_taxons.recurring, :root_taxon],
    [:ordered_related_items, :mainstream_browse_pages, :parent.recurring],
    [:ordered_related_items_overrides, :taxons]
  ].freeze

  REVERSE_LINKS = {
    parent: :children,
    documents: :document_collections,
    working_groups: :policies,
    parent_taxons: :child_taxons,
    root_taxon: :level_one_taxons,
    pages_part_of_step_nav: :part_of_step_navs,
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
    { document_type: :taxon,                      fields: DEFAULT_FIELDS_WITH_DETAILS + [:phase] },
    { document_type: :need,                       fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :finder, link_type: :finder, fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :step_by_step_nav,           fields: DEFAULT_FIELDS_WITH_DETAILS },
    { document_type: :travel_advice,              fields: DEFAULT_FIELDS + [[:details, :country], [:details, :change_description]] },
    { document_type: :world_location,             fields: [:content_id, :title, :schema_name, :locale, :analytics_identifier] },
  ].freeze

  POSSIBLE_FIELDS_FOR_LINK_EXPANSION = DEFAULT_FIELDS_WITH_DETAILS +
    %i[id state phase unpublishings.type] -
    %i[api_path withdrawn]

  def reverse_links
    REVERSE_LINKS.values
  end

  def reverse_link_type(link_type)
    REVERSE_LINKS[link_type.to_sym]
  end

  def reverse_to_direct_link_type(link_type)
    REVERSE_LINKS.key(link_type.to_sym)
  end

  def is_reverse_link_type?(link_type)
    reverse_to_direct_link_type(link_type).present?
  end

  def reverse_to_direct_link_types(link_types)
    return unless link_types
    link_types.map { |type| reverse_to_direct_link_type(type) }.compact
  end

  def reverse_link_types_hash(link_types)
    link_types.each_with_object({}) do |(link_type, content_ids), memo|
      reversed = reverse_link_type(link_type)
      memo[reversed] = content_ids if reversed
    end
  end

  def link_expansion
    @link_expansion ||= ExpansionRules::LinkExpansion.new(self)
  end

  def dependency_resolution
    @dependency_resolution ||= ExpansionRules::DependencyResolution.new(self)
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

  def next_allowed_direct_link_types(next_allowed_link_types, reverse_to_direct: false)
    next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
      next if allowed_links.empty?

      link_type = (reverse_to_direct_link_type(link_type) || link_type) if reverse_to_direct

      links = allowed_links.select { |link| !is_reverse_link_type?(link) }

      memo[link_type] = links unless links.empty?
    end
  end

  def next_allowed_reverse_link_types(next_allowed_link_types, reverse_to_direct: false)
    next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
      next if allowed_links.empty?
      link_type = (reverse_to_direct_link_type(link_type) || link_type) if reverse_to_direct

      links = allowed_links.select { |link| is_reverse_link_type?(link) }

      links = reverse_to_direct_link_types(links) if reverse_to_direct

      memo[link_type] = links unless links.empty?
    end
  end
end
