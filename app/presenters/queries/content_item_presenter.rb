module Presenters
  module Queries
    class ContentItemPresenter
      attr_reader :edition_scope,
                  :fields,
                  :order,
                  :limit,
                  :offset,
                  :search_query,
                  :search_in,
                  :states,
                  :include_warnings

      DEFAULT_FIELDS = ([
        *Edition::TOP_LEVEL_FIELDS,
        :publication_state,
        :content_id,
        :unpublishing,
        :locale,
        :lock_version,
        :updated_at,
        :state_history,
        :change_note,
        :links,
      ] - [:state]).freeze # state appears as 'publication_state'

      DEFAULT_SEARCH_FIELDS = %w[title base_path].freeze

      SEARCH_FIELDS = %w[title base_path description].freeze
      NESTED_SEARCH_FIELDS = %w[details].freeze

      def self.present_many(edition_scope, params = {})
        new(edition_scope, params).present_many
      end

      def self.present(edition, params = {})
        scope = Edition.where(id: edition.id)
        present_many(scope, params).first
      end

      def initialize(edition_scope, params = {})
        @edition_scope = edition_scope
        @fields = (params[:fields] || DEFAULT_FIELDS).map(&:to_sym)
        @order = params[:order] || { id: "asc" }
        @limit = params[:limit]
        @offset = params[:offset]
        @search_query = params[:search_query]
        @search_in = params[:search_in] || DEFAULT_SEARCH_FIELDS
        @states = Array(params[:states]).map(&:to_sym) if params[:states].present?
        @states ||= %i[draft published unpublished]
        @include_warnings = params[:include_warnings] || false
      end

      def present_many
        parse_results(results)
      end

      def total
        results.first.nil? ? 0 : results.first["total"]
      end

    private

      def results
        @results ||= execute_query(query)
      end

      def query
        ordering_query = Edition.select("*, COUNT(*) OVER () as total").from(fetch_items_query)
        ordering_query = join_lateral_aggregates(ordering_query)
        ordering_query = ordering_query.order(order.map { |o| o.join(" ") }.join(", ")) if order
        ordering_query = ordering_query.limit(limit) if limit
        ordering_query = ordering_query.offset(offset) if offset
        ordering_query
      end

      def fetch_items_query
        query = edition_scope.where(state: states)
        query = join_supporting_objects(query)
        query = search(query)
        query = reorder(query)
        select_fields(query)
      end

      def join_supporting_objects(scope)
        scope = scope.with_document
        scope = scope.with_change_note if fields.include?(:change_note)
        scope = scope.with_unpublishing if fields.include?(:unpublishing)
        scope
      end

      def search(scope)
        return scope if search_query.blank?

        conditions = search_in.map { |search_field| "#{search_field} ilike :query" }
        scope.where(conditions.join(" OR "), query: "%#{search_query}%")
      end

      def reorder(scope)
        # used for distinct document_id by state and latest version
        scope.reorder(["editions.document_id", state_order_clause, "user_facing_version DESC"].compact)
      end

      # If there are multiple editions for a document, pick the draft, then the
      # published/unpublished. This is expensive, so only add if needed.
      def state_order_clause
        priorities = { draft: 0, published: 1, unpublished: 1, superseded: 2 }.slice(*states)
        return unless priorities.values.uniq.count > 1

        Arel.sql("CASE state #{priorities.map { |k, v| "WHEN '#{k}' THEN #{v} " }.join} END")
      end

      def field_selector(field)
        case field
        when :publication_state
          "editions.state AS publication_state"
        when :user_facing_version
          "editions.user_facing_version AS user_facing_version"
        when :lock_version
          "documents.stale_lock_version AS lock_version"
        when :last_edited_at
          "to_char(last_edited_at, '#{ISO8601_SQL}') as last_edited_at"
        when :public_updated_at
          "to_char(public_updated_at, '#{ISO8601_SQL}') as public_updated_at"
        when :first_published_at
          "to_char(first_published_at, '#{ISO8601_SQL}') as first_published_at"
        when :published_at
          "to_char(published_at, '#{ISO8601_SQL}') as published_at"
        when :major_published_at
          "to_char(major_published_at, '#{ISO8601_SQL}') as major_published_at"
        when :publishing_api_last_edited_at
          "to_char(publishing_api_last_edited_at, '#{ISO8601_SQL}') as publishing_api_last_edited_at"
        when :publishing_api_first_published_at
          "to_char(publishing_api_first_published_at, '#{ISO8601_SQL}') as publishing_api_first_published_at"
        when :updated_at
          "to_char(editions.updated_at, '#{ISO8601_SQL}') as updated_at"
        when :unpublishing
          "#{UNPUBLISHING_SQL} AS unpublishing"
        when :change_note
          "change_notes.note AS change_note"
        when :base_path
          "editions.base_path as base_path"
        when :locale
          "documents.locale as locale"
        when :content_id
          "documents.content_id as content_id"
        when :state_history
          nil
        when :links
          nil
        when :total
          nil
        else
          field
        end
      end

      def select_fields(scope)
        fields_to_select = (fields + order.map(&:first)).map do |field|
          field_selector(field)
        end

        fields = [
          "DISTINCT ON(editions.document_id) editions.document_id",
        ] + fields_to_select.compact

        scope.select(*fields)
      end

      STATE_HISTORY_SQL = <<-SQL.freeze
        (
          SELECT json_agg((user_facing_version, state)) AS state_history
          FROM editions e
          WHERE e.document_id = subquery.document_id
          GROUP BY subquery.content_id
        ) state_history_subquery
      SQL

      LINKS_SQL = <<-SQL.freeze
        (
          SELECT json_agg((links.link_type, links.target_content_id)) AS links
          FROM links
          WHERE links.edition_id = subquery.id
        ) links_subquery
      SQL

      LATERAL_AGGREGATES = {
        state_history: STATE_HISTORY_SQL,
        links: LINKS_SQL,
      }.freeze

      def join_lateral_aggregates(scope)
        LATERAL_AGGREGATES.each do |field, sql|
          next unless fields.include?(field)

          scope = scope.joins("LEFT JOIN LATERAL #{sql} ON TRUE")
        end
        scope
      end

      ISO8601_SQL = "YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"".freeze

      # Creating a JSON object with specified keys in PostgreSQL 9.3
      # is a little awkward, but is possible through the use of column
      # aliases
      UNPUBLISHING_SQL = <<-SQL.freeze
        (
          SELECT
            CASE WHEN unpublishings.edition_id IS NULL THEN NULL
                 ELSE row_to_json(unpublishing_data)
            END
          FROM (
            VALUES (
              unpublishings.type,
              unpublishings.explanation,
              unpublishings.alternative_path,
              unpublishings.redirects,
              to_char(unpublishings.unpublished_at, '#{ISO8601_SQL}')
            )
          )
          AS
          unpublishing_data(
            type,
            explanation,
            alternative_path,
            redirects,
            unpublished_at
          )
        )
      SQL

      def parse_results(results)
        json_columns = %w[details routes redirects state_history unpublishing links]
        int_columns = %w[user_facing_version lock_version]

        Enumerator.new do |yielder|
          results.each do |result|
            json_columns.each { |c| parse_json_column(result, c) }
            int_columns.each { |c| parse_int_column(result, c) }
            parse_auth_bypass_ids_column(result, "auth_bypass_ids")

            parse_state_history(result)
            parse_links(result, "links")

            result.slice!(*fields.map(&:to_s))

            result["warnings"] = get_warnings(result) if include_warnings

            yielder.yield(result.except("total").compact)
          end
        end
      end

      def parse_json_column(result, column)
        return unless result.key?(column)
        return if result[column].nil?

        result[column] = Oj.load(result[column])
      end

      def parse_int_column(result, column)
        return unless result.key?(column)

        result[column] = result[column].to_i
      end

      def parse_auth_bypass_ids_column(result, column)
        return unless result.key?(column)

        result[column] = result[column].delete("{}").split(",")
      end

      def parse_links(result, column)
        return unless result.key?(column)

        result[column] = Array(result[column]).map(&:values)
          .group_by(&:first)
          .each_with_object({}) do |(key, value), a|
            a[key] = value.flatten.reject { |v| v == key }
          end
      end

      def parse_state_history(result)
        column = "state_history"
        return unless result.key?(column)

        result[column] = result[column].map(&:values).to_h
      end

      def get_warnings(result)
        required_fields = %i[
          content_id
          state_history
          user_facing_version
          base_path
          document_type
        ]

        missing_fields = required_fields - fields

        unless missing_fields.empty?
          raise "#{missing_fields} must be included if the include_warnings parameter is true"
        end

        Presenters::Queries::ContentItemWarnings.call(
          result["content_id"],
          result["state_history"][result["user_facing_version"]],
          result["base_path"],
          result["document_type"],
        )
      end

      # It is substantially faster to evaluate in this way rather than calling
      # the #pluck or #as_json methods.
      def execute_query(query)
        ActiveRecord::Base.connection.execute(query.to_sql)
      end
    end
  end
end
