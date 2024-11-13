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

    DEFAULT_PER_PAGE = 10

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

    ORDER_FIELDS = {
      title: TABLES[:editions][:title],
      document_type: TABLES[:editions][:document_type],
      unique_pageviews: TABLES[:statistics_caches][:unique_pageviews],
      primary_publishing_organisation_title: TABLES[:org_editions][:title],
      last_edited_at: TABLES[:editions][:last_edited_at],
    }.freeze

    ORDER_DIRECTIONS = %i[asc desc].freeze

    attr_reader :target_content_id, :state, :order_field, :order_direction, :page, :per_page

    def initialize(target_content_id, order_field: nil, order_direction: nil, page: nil, per_page: nil)
      @target_content_id = target_content_id
      @state = "published"
      @order_direction = ORDER_DIRECTIONS.include?(order_direction || :asc) ? order_direction : raise(KeyError, "Unknown order direction: #{order_direction}")
      @order_field = ORDER_FIELDS.fetch(order_field || :unique_pageviews) { |k| raise KeyError, "Unknown order field: #{k}" }
      @page = page || 0
      @per_page = per_page || DEFAULT_PER_PAGE
    end

    def call
      results = ActiveRecord::Base.connection.select_all(paginated_query).to_a
      results.map do |row|
        Result.new(**row)
      end
    end

    def count
      @count ||= ActiveRecord::Base.connection.select_value(count_query)
    end

    def total_pages
      (count.to_f / per_page).ceil
    end

  private

    def paginated_query
      arel_query.take(per_page).skip(page * per_page)
    end

    def arel_query
      arel_joins.where(
        TABLES[:editions][:state].eq(state)
                                 .and(TABLES[:links][:link_type].eq(embedded_link_type))
                                 .and(TABLES[:links][:target_content_id].eq(target_content_id)),
      ).order(order_direction == :desc ? order_field.desc : order_field.asc)
    end

    def count_query
      "SELECT COUNT(*) FROM (#{arel_query.to_sql}) AS full_query"
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
