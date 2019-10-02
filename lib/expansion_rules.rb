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

  def details_fields(*fields)
    fields.map { |field| [:details, field] }
  end

  MULTI_LEVEL_LINK_PATHS = [
    [:associated_taxons.recurring],
    [:child_taxons, :associated_taxons.recurring],
    [:child_taxons.recurring, :legacy_taxons],
    [:child_taxons.recurring],
    [:parent.recurring],
    [:parent_taxons.recurring],
    [:parent_taxons.recurring, :root_taxon],
    [:taxons, :root_taxon],
    [:taxons, :parent_taxons.recurring],
    [:taxons, :parent_taxons.recurring, :root_taxon],
    [:ordered_related_items, :mainstream_browse_pages, :parent.recurring],
    [:ordered_related_items_overrides, :taxons],
    [:facets, :facet_values, :facet_group],
    [:facet_group, :facets, :facet_values],
  ].freeze

  REVERSE_LINKS = {
    parent: :children,
    documents: :document_collections,
    working_groups: :policies,
    parent_taxons: :child_taxons,
    root_taxon: :level_one_taxons,
    pages_part_of_step_nav: :part_of_step_navs,
    pages_related_to_step_nav: :related_to_step_navs,
    legacy_taxons: :topic_taxonomy_taxons,
    pages_secondary_to_step_nav: :secondary_to_step_navs,
  }.freeze

  DEFAULT_FIELDS = [
    :analytics_identifier,
    :api_path,
    :base_path,
    :content_id,
    :document_type,
    :locale,
    :public_updated_at,
    :schema_name,
    :title,
    :withdrawn,
  ].freeze

  DEFAULT_FIELDS_AND_DESCRIPTION = (DEFAULT_FIELDS + [:description]).freeze

  CONTACT_FIELDS = (DEFAULT_FIELDS + details_fields(:description, :title, :contact_form_links, :post_addresses, :email_addresses, :phone_numbers)).freeze
  ORGANISATION_FIELDS = (DEFAULT_FIELDS - [:public_updated_at] + details_fields(:logo, :brand, :default_news_image)).freeze
  TAXON_FIELDS = (DEFAULT_FIELDS + %i(description details phase)).freeze
  NEED_FIELDS = (DEFAULT_FIELDS + details_fields(:role, :goal, :benefit, :met_when, :justifications)).freeze
  FINDER_FIELDS = (DEFAULT_FIELDS + details_fields(:facets)).freeze
  ROLE_APPOINTMENT_FIELDS = (DEFAULT_FIELDS + details_fields(:started_on, :ended_on)).freeze
  STEP_BY_STEP_FIELDS = (DEFAULT_FIELDS + [%i(details step_by_step_nav title), %i(details step_by_step_nav steps)]).freeze
  STEP_BY_STEP_AUTH_BYPASS_FIELDS = (STEP_BY_STEP_FIELDS + %i(auth_bypass_id)).freeze
  TRAVEL_ADVICE_FIELDS = (DEFAULT_FIELDS + details_fields(:country, :change_description)).freeze
  WORLD_LOCATION_FIELDS = [:content_id, :title, :schema_name, :locale, :analytics_identifier].freeze
  FACET_GROUP_FIELDS = (%i[content_id title locale schema_name] + details_fields(:name, :description)).freeze
  FACET_FIELDS = (
    %i[content_id title locale schema_name] + details_fields(
      :combine_mode,
      :display_as_result_metadata,
      :filterable,
      :filter_key,
      :key,
      :name,
      :preposition,
      :short_name,
      :type,
    )
  ).freeze
  FACET_VALUE_FIELDS = (%i[content_id title locale schema_name] + details_fields(:label, :value)).freeze

  CUSTOM_EXPANSION_FIELDS = [
    { document_type: :redirect,
      fields: [] },
    { document_type: :gone,
      fields: [] },
    { document_type: :contact,
      fields: CONTACT_FIELDS },
    { document_type: :topical_event,
      fields: DEFAULT_FIELDS },
    { document_type: :placeholder_topical_event,
      fields: DEFAULT_FIELDS },
    { document_type: :organisation,
      fields: ORGANISATION_FIELDS },
    { document_type: :placeholder_organisation,
      fields: ORGANISATION_FIELDS },
    { document_type: :taxon,
      fields: TAXON_FIELDS },
    { document_type: :need,
      fields: NEED_FIELDS },
    { document_type: :finder,
      link_type: :finder,
      fields: FINDER_FIELDS },
    { document_type: :mainstream_browse_page,
      fields: DEFAULT_FIELDS_AND_DESCRIPTION },
    { document_type: :role_appointment,
      fields: ROLE_APPOINTMENT_FIELDS },
    { document_type: :service_manual_topic,
      fields: DEFAULT_FIELDS_AND_DESCRIPTION },
    { document_type: :step_by_step_nav,
      link_type: :part_of_step_navs,
      fields: STEP_BY_STEP_AUTH_BYPASS_FIELDS },
    { document_type: :step_by_step_nav,
      link_type: :related_to_step_navs,
      fields: STEP_BY_STEP_AUTH_BYPASS_FIELDS },
    { document_type: :step_by_step_nav,
      fields: STEP_BY_STEP_FIELDS },
    { document_type: :travel_advice,
      fields: TRAVEL_ADVICE_FIELDS },
    { document_type: :world_location,
      fields: WORLD_LOCATION_FIELDS },
    { document_type: :facet_group,
      fields: FACET_GROUP_FIELDS },
    { document_type: :facet,
      fields: FACET_FIELDS },
    { document_type: :facet_value,
      fields: FACET_VALUE_FIELDS },
  ].freeze

  POSSIBLE_FIELDS_FOR_LINK_EXPANSION = DEFAULT_FIELDS +
    %i[details] +
    %i[id state phase description unpublishings.type auth_bypass_id] -
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
    should_check_link_type = options[:link_type]
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

  module HashWithDigSet
    refine Hash do
      def dig_set(keys, value)
        keys.each_with_index.inject(self) do |hash, (key, index)|
          if keys.count - 1 == index
            hash[key] = value
          else
            hash[key] ||= {}
          end
        end
      end
    end
  end

  using HashWithDigSet

  def expand_fields(edition_hash, link_type)
    expansion_fields(edition_hash[:document_type], link_type).each_with_object({}) do |field, expanded|
      field = Array(field)
      # equivelant to: expanded.dig(*field) = edition_hash.dig(*field)
      expanded.dig_set(field, edition_hash.dig(*field))
    end
  end

  def next_allowed_direct_link_types(next_allowed_link_types, reverse_to_direct: false)
    next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
      next if allowed_links.empty?

      link_type = (reverse_to_direct_link_type(link_type) || link_type) if reverse_to_direct

      links = allowed_links.reject { |link| is_reverse_link_type?(link) }

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
