module Queries
  class GetHostContent
    Result = Data.define(
      :id,
      :title,
      :base_path,
      :document_type,
      :publishing_app,
      :last_edited_by_editor_id,
      :last_edited_at,
      :host_content_id,
      :host_locale,
      :primary_publishing_organisation_content_id,
      :primary_publishing_organisation_title,
      :primary_publishing_organisation_base_path,
      :unique_pageviews,
      :instances,
    )

    Rollup = Data.define(
      :views,
      :locations,
      :instances,
      :organisations,
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
      { field: TABLES[:editions][:id], alias: "id", included_in_group?: true },
      { field: TABLES[:editions][:title], alias: "title", included_in_group?: true },
      { field: TABLES[:editions][:base_path], alias: "base_path", included_in_group?: true },
      { field: TABLES[:editions][:document_type], alias: "document_type", included_in_group?: true },
      { field: TABLES[:editions][:publishing_app], alias: "publishing_app", included_in_group?: true },
      { field: TABLES[:editions][:last_edited_by_editor_id], alias: "last_edited_by_editor_id", included_in_group?: true },
      { field: TABLES[:editions][:last_edited_at], alias: "last_edited_at", included_in_group?: true },
      { field: TABLES[:primary_links][:target_content_id], alias: "primary_publishing_organisation_content_id", included_in_group?: true },
      { field: TABLES[:org_editions][:title], alias: "primary_publishing_organisation_title", included_in_group?: true },
      { field: TABLES[:org_editions][:base_path], alias: "primary_publishing_organisation_base_path", included_in_group?: true },
      { field: TABLES[:statistics_caches][:unique_pageviews], alias: "unique_pageviews", included_in_group?: true },
      { field: TABLES[:documents][:content_id], alias: "host_content_id", included_in_group?: true },
      { field: TABLES[:documents][:locale], alias: "host_locale", included_in_group?: true },
      { field: TABLES[:editions][:id].count, alias: "instances", included_in_group?: false },
    ].freeze

    ORDER_FIELDS = {
      title: TABLES[:editions][:title],
      document_type: TABLES[:editions][:document_type],
      unique_pageviews: TABLES[:statistics_caches][:unique_pageviews],
      primary_publishing_organisation_title: TABLES[:org_editions][:title],
      last_edited_at: TABLES[:editions][:last_edited_at],
      instances: TABLES[:editions][:id].count,
    }.freeze

    ORDER_DIRECTIONS = %i[asc desc].freeze

    attr_reader :target_content_id, :state, :order_field, :order_direction, :page, :per_page, :host_content_id, :locale

    def initialize(target_content_id, order_field: nil, order_direction: nil, page: nil, per_page: nil, host_content_id: nil, locale: nil)
      @target_content_id = target_content_id
      @state = "published"
      @order_direction = ORDER_DIRECTIONS.include?(order_direction || :asc) ? order_direction : raise(KeyError, "Unknown order direction: #{order_direction}")
      @order_field = ORDER_FIELDS.fetch(order_field || :unique_pageviews) { |k| raise KeyError, "Unknown order field: #{k}" }
      @page = page || 0
      @per_page = per_page || DEFAULT_PER_PAGE
      @host_content_id = host_content_id
      @locale = locale
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

    def rollup
      Rollup.new(**ActiveRecord::Base.connection.select_one(rollup_query))
    end

  private

    def paginated_query
      arel_query.take(per_page).skip(page * per_page)
    end

    def arel_query
      arel_joins
        .where(clauses)
        .order(order_direction == :desc ? order_field.desc.nulls_last : order_field.asc)
    end

    def clauses
      clauses = TABLES[:editions][:state].eq(state)
                                         .and(TABLES[:links][:link_type].eq(embedded_link_type))
                                         .and(TABLES[:links][:target_content_id].eq(target_content_id))

      clauses = clauses.and(TABLES[:documents][:content_id]).eq(host_content_id) if host_content_id
      clauses = clauses.and(TABLES[:documents][:locale]).eq(locale) if locale

      clauses
    end

    def count_query
      "SELECT COUNT(*) FROM (#{arel_query.to_sql}) AS full_query"
    end

    def rollup_query
      subquery = arel_query.as(Arel.sql("totals"))
      TABLES[:editions].project(
        subquery[:unique_pageviews].sum.as("views"),
        subquery[:id].count.as("locations"),
        subquery[:instances].sum.as("instances"),
        subquery[:primary_publishing_organisation_content_id].count(true).as("organisations"),
      ).from(subquery)
    end

    def select_fields
      FIELDS.map { |f| f[:field].as(f[:alias]) }
    end

    def group_fields
      FIELDS.select { |f| f[:included_in_group?] }.pluck(:field)
    end

    def arel_joins
      TABLES[:editions]
        .project(select_fields)
        .join(TABLES[:links]).on(
          TABLES[:links][:edition_id].eq(TABLES[:editions][:id]),
        )
        .join(TABLES[:documents]).on(
          TABLES[:documents][:id].eq(TABLES[:editions][:document_id]),
        )
        .join(TABLES[:primary_links], Arel::Nodes::OuterJoin).on(
          TABLES[:primary_links][:edition_id].eq(
            TABLES[:editions][:id],
          ).or(
            TABLES[:primary_links][:link_set_content_id].eq(TABLES[:documents][:content_id]),
          ),
          TABLES[:primary_links][:link_type].eq("primary_publishing_organisation"),
        )
        .join(TABLES[:org_documents], Arel::Nodes::OuterJoin).on(
          TABLES[:org_documents][:content_id].eq(TABLES[:primary_links][:target_content_id]),
          TABLES[:org_documents][:locale].eq("en"),
        )
        .join(TABLES[:org_editions], Arel::Nodes::OuterJoin).on(
          TABLES[:org_editions][:document_id].eq(TABLES[:org_documents][:id]),
          TABLES[:org_editions][:state].eq("published"),
        )
        .join(TABLES[:statistics_caches], Arel::Nodes::OuterJoin).on(
          TABLES[:statistics_caches][:document_id].eq(TABLES[:documents][:id]),
        )
        .group(group_fields)
    end

    def embedded_link_type
      "embed"
    end
  end
end
