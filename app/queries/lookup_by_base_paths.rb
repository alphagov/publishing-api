module Queries
  module LookupByBasePaths
    def self.call(base_paths)
      base_paths_and_content_ids = Edition.with_document
        .left_outer_joins(:unpublishing)
        .left_outer_joins(:access_limit)
        .where(base_path: base_paths)
        .where("access_limits.edition_id IS NULL")
        .where("state != 'superseded'")
        .order(:base_path)
        .order(:state)
        .order(user_facing_version: :desc)
        .pluck(
          %{
            DISTINCT ON (editions.base_path, editions.state)
            editions.base_path,
            documents.content_id,
            documents.locale,
            editions.document_type,
            CASE editions.state WHEN 'draft' THEN 'draft' ELSE 'live' END,
            unpublishings.type,
            unpublishings.alternative_path
          }
        )

      lookups = base_paths_and_content_ids.group_by(&:first)

      lookups.each_with_object({}) do |group, result|
        base_path, rows = group
        result[base_path] = build_lookup(rows)
      end
    end

    def self.build_lookup(rows)
      rows.each_with_object({}) do |row, lookup|
        _, content_id, locale, document_type, state, unpublishing_type, alternative_path = row

        content_item = {
          "content_id" => content_id,
          "locale" => locale,
          "document_type" => document_type,
        }

        if unpublishing_type.present?
          content_item["unpublishing"] = {
            "type" => unpublishing_type,
            "alternative_path" => alternative_path
          }.compact
        end

        lookup[state] = content_item
      end
    end

    private_class_method :build_lookup
  end
end
