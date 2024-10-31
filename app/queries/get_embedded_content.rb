module Queries
  class GetEmbeddedContent
    Result = Data.define(
      :id,
      :title,
      :base_path,
      :document_type,
      :publishing_app,
      :last_edited_by_editor_id,
      :last_edited_at,
      :primary_publishing_organisation_content_id,
      :primary_publishing_organisation_title,
      :primary_publishing_organisation_base_path,
      :unique_pageviews,
    )

    SQL = <<-SQL.freeze
        SELECT
            editions.id,
            editions.title,
            editions.base_path,
            editions.document_type,
            editions.publishing_app,
            editions.last_edited_by_editor_id,
            editions.last_edited_at,
            primary_links.target_content_id AS primary_publishing_organisation_content_id,
            org_editions.title AS primary_publishing_organisation_title,
            org_editions.base_path AS primary_publishing_organisation_base_path,
            statistics_caches.unique_pageviews AS unique_pageviews
          FROM "editions"
            INNER JOIN "links" ON "links"."edition_id" = "editions"."id"
            INNER JOIN "documents" ON "documents"."id" = "editions"."document_id"
            LEFT JOIN links AS primary_links ON primary_links.edition_id = editions.id AND primary_links.link_type = 'primary_publishing_organisation'
            LEFT JOIN documents AS org_documents ON org_documents.content_id = primary_links.target_content_id
            LEFT JOIN editions AS org_editions ON org_editions.document_id = org_documents.id AND org_editions.state = 'published'
            LEFT JOIN statistics_caches ON statistics_caches.document_id = documents.id
            WHERE "editions"."state" = $1 AND "links"."link_type" = $2 AND "links"."target_content_id" = $3
    SQL

    attr_reader :target_content_id, :state

    def initialize(target_content_id)
      @target_content_id = target_content_id
      @state = "published"
    end

    def call
      # Prepare params to bind to the SQL query - ActiveRecord requires params to be sent as QueryAttributes,
      # see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-select_all
      bind_params = [
        ActiveRecord::Relation::QueryAttribute.new("state", state, ActiveRecord::Type::Text.new),
        ActiveRecord::Relation::QueryAttribute.new("embedded_link_type", embedded_link_type, ActiveRecord::Type::Text.new),
        ActiveRecord::Relation::QueryAttribute.new("target_content_id", target_content_id, ActiveRecord::Type::Text.new),
      ]
      results = ActiveRecord::Base.connection.select_all(SQL, "SQL", bind_params).to_a
      results.map do |row|
        Result.new(**row)
      end
    end

  private

    def embedded_link_type
      "embed"
    end
  end
end
