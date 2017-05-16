module Queries
  module LookupByBasePaths
    def self.call(base_paths)
      # Ensure we have a key for every requested base path
      response = {}
      base_paths.each do |base_path|
        response[base_path] = nil
      end

      grouped_rows = Edition
        .with_document
        .with_unpublishing
        .with_access_limit
        .where(base_path: base_paths, "access_limits.edition_id": nil)
        .where.not(content_store: nil)
        .order(:base_path, :content_store, user_facing_version: :desc)
        .pluck(
          %{
            DISTINCT ON (editions.base_path, editions.content_store)
            editions.base_path,
            documents.content_id,
            documents.locale,
            editions.document_type,
            editions.content_store,
            unpublishings.type,
            unpublishings.redirects
          }
        ).group_by(&:first)

      grouped_rows.each do |group|
        base_path, rows = group
        response[base_path] = build_lookup(rows)
      end

      response
    end

    def self.build_lookup(rows)
      rows.each_with_object({}) do |row, lookup|
        _, content_id, locale, document_type, content_store, unpublishing_type, redirects = row

        content_item = {
          "content_id" => content_id,
          "locale" => locale,
          "document_type" => document_type,
        }

        if unpublishing_type.present?
          content_item["unpublishing"] = {
            "type" => unpublishing_type,
            "redirects" => redirects
          }.compact
        end

        lookup[content_store] = content_item
      end
    end

    private_class_method :build_lookup
  end
end
