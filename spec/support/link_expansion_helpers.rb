module LinkExpansionHelpers
  def expected_link_paths_for_schema(schema_name, schema, length)
    multi_level_links = ExpansionRules::MultiLevelLinks.new(ExpansionRules::MULTI_LEVEL_LINK_PATHS)
    all_paths = (1..length).flat_map { multi_level_links.paths(length: _1) }.uniq
    complete_paths = remove_prefixes(all_paths)

    ignored_links = [
      (:child_taxons unless schema_name == "taxon"),
      (:level_one_taxons unless schema_name == "homepage"),
      (:ministers unless schema_name == "ministers_index"),
      :policies, # Reverse of working_groups - no longer exists as all editions for the policy schema have been unpublished and redirected
      :emphasised_organisations, # Not in use
      :suggested_ordered_related_items, # Not in use
    ].compact

    all_schema_links = (schema.dig("properties", "links", "properties")&.keys || []).map(&:to_sym)
    schema_links = all_schema_links - ignored_links
    multi_level_link_paths_in_schema = complete_paths.select { |p| schema_links.include?(p.first) }
    single_level_link_paths_in_schema = schema_links
                                          .reject { |link| multi_level_link_paths_in_schema.map(&:first).include?(link) }
                                          .map { |link| [link] }
    single_level_link_paths_in_schema.union(multi_level_link_paths_in_schema)
  end

private

  def remove_prefixes(arrays)
    arrays.reject do |array|
      arrays.any? do |other|
        other.length > array.length && other[0, array.length] == array
      end
    end
  end
end
