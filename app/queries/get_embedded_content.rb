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


    attr_reader :target_content_id, :state

    def initialize(target_content_id)
    TABLES = {
      editions: Edition.arel_table,
      documents: Document.arel_table,
      links: Link.arel_table,
      primary_links: Link.arel_table.alias(:primary_links),
      org_editions: Edition.arel_table.alias(:org_editions),
      org_documents: Document.arel_table.alias(:org_documents),
      statistics_caches: StatisticsCache.arel_table,
    }.freeze

    FIELDS = [
      TABLES[:editions][:id],
      TABLES[:editions][:title],
      TABLES[:editions][:base_path],
      TABLES[:editions][:document_type],
      TABLES[:editions][:publishing_app],
      TABLES[:editions][:last_edited_by_editor_id],
      TABLES[:editions][:last_edited_at],
      TABLES[:primary_links][:target_content_id].as("primary_publishing_organisation_content_id"),
      TABLES[:org_editions][:title].as("primary_publishing_organisation_title"),
      TABLES[:org_editions][:base_path].as("primary_publishing_organisation_base_path"),
      TABLES[:statistics_caches][:unique_pageviews],
    ].freeze

      @target_content_id = target_content_id
      @state = "published"
    end

    def call
      results = ActiveRecord::Base.connection.select_all(arel_query).to_a
      results.map do |row|
        Result.new(**row)
      end
    end

  private

    def arel_query
      arel_joins.where(
        TABLES[:editions][:state].eq(state)
                                 .and(TABLES[:links][:link_type].eq(embedded_link_type))
                                 .and(TABLES[:links][:target_content_id].eq(target_content_id)),
      )
    end

    def arel_joins
      TABLES[:editions]
        .project(FIELDS)
        .join(TABLES[:links]).on(
          TABLES[:links][:edition_id].eq(TABLES[:editions][:id]),
        )
        .join(TABLES[:documents]).on(
          TABLES[:documents][:id].eq(TABLES[:editions][:document_id]),
        )
        .join(TABLES[:primary_links], Arel::Nodes::OuterJoin).on(
          TABLES[:primary_links][:edition_id].eq(TABLES[:editions][:id]),
          TABLES[:primary_links][:link_type].eq("primary_publishing_organisation"),
        )
        .join(TABLES[:org_documents], Arel::Nodes::OuterJoin).on(
          TABLES[:org_documents][:content_id].eq(TABLES[:primary_links][:target_content_id]),
        )
        .join(TABLES[:org_editions], Arel::Nodes::OuterJoin).on(
          TABLES[:org_editions][:document_id].eq(TABLES[:org_documents][:id]),
          TABLES[:org_editions][:state].eq("published"),
        )
        .join(TABLES[:statistics_caches], Arel::Nodes::OuterJoin).on(
          TABLES[:statistics_caches][:document_id].eq(TABLES[:documents][:id]),
        )
    end

    def embedded_link_type
      "embed"
    end
  end
end
