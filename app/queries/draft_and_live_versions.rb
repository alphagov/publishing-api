module Queries
  module DraftAndLiveVersions
    extend ArelHelpers
    def self.call(content_item, target_class, locale = nil, base_path = nil)
      content_items_table = table(:content_items)
      states_table = table(:states)
      translations_table = table(:translations)
      locations_table = table(:locations)
      versions_table = table(target_class)
      versions_fk = target_class == "lock_versions" ? :target_id : :content_item_id

      if base_path.nil?
        base_path = locations_table.project(locations_table[:base_path])
          .where(locations_table[:content_item_id].eq(content_item.id))
      end
      if locale.nil?
        locale = translations_table.project(translations_table[:locale])
          .where(translations_table[:content_item_id].eq(content_item.id))
      end

      scope = content_items_table
        .project(
          Arel::Nodes::NamedFunction.new("row_number", [])
            .over(Arel::Nodes::Window.new
              .partition(states_table[:name])
              .order(versions_table[:number])
            ).as("r"),
          states_table[:name].as("state"),
          versions_table[:number].as("version_number")
        )
        .outer_join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .outer_join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .outer_join(locations_table).on(
          content_items_table[:id].eq(locations_table[:content_item_id])
        )
        .outer_join(versions_table).on(
          content_items_table[:id].eq(versions_table[versions_fk])
        )
        .where(content_items_table[:content_id].eq(content_item.content_id))
        .where(locations_table[:base_path].eq(base_path))
        .where(translations_table[:locale].eq(locale))
        .where(states_table[:name].in(%w(draft published)))

      partitioned = cte(scope, as: :partitioned)
      query = partitioned.table.project(Arel.star)
        .with(partitioned.compiled_scope)
        .where(partitioned.table[:r].eq(1))

      Hash[get_rows(query).map { |i| [i["state"], i["version_number"].to_i] }]
    end
  end
end
