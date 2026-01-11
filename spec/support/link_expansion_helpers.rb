module LinkExpansionHelpers
  def expected_link_paths_for_schema(schema_name, schema, length)
    multi_level_links = ExpansionRules::MultiLevelLinks.new(ExpansionRules::MULTI_LEVEL_LINK_PATHS).paths(length:)
    # Hack 1:
    multi_level_links = multi_level_links.reject { _1 == %i[role_appointments role] }
    # Hack 2:
    multi_level_links = multi_level_links + [
      %i[taxons parent_taxons root_taxon],
      %i[taxons parent_taxons parent_taxons root_taxon],
    ]
    # Hack 3:
    ignored_links = [
      (:child_taxons unless schema_name == "taxon"),
      :emphasised_organisations,
      (:level_one_taxons unless schema_name == "homepage"),
      :ministers,
      :policies,
      :suggested_ordered_related_items,
    ].compact

    schema_links = (schema.dig("properties", "links", "properties")&.keys || []).map(&:to_sym) - ignored_links
    multi_level_link_paths_in_schema = multi_level_links.select { |p| schema_links.include?(p.first) }
    single_level_link_paths_in_schema = schema_links
                                          .reject { |link| multi_level_link_paths_in_schema.map(&:first).include?(link) }
                                          .map { |link| [link] }
    single_level_link_paths_in_schema.union(multi_level_link_paths_in_schema)

  end
end