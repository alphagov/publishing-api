module Presenters
  module Queries
    class ContentItemPresenter
      attr_accessor :scope, :fields, :order, :limit, :offset, :search_query,
                    :search_in, :include_warnings

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

      DEFAULT_SEARCH_FIELDS = %w(title base_path).freeze

      SEARCH_FIELDS = %w(title base_path description).freeze
      NESTED_SEARCH_FIELDS = %w(details).freeze

      def self.present_many(scope, params = {})
        new(scope, params).present_many
      end

      def self.present(edition, params = {})
        scope = Edition.where(id: edition.id)

        present_many(scope, params).first
      end

      def initialize(scope, params = {})
        self.scope = scope
        self.fields = (params[:fields] || DEFAULT_FIELDS).map(&:to_sym)
        self.order = params[:order] || { "editions.id" => "asc" }
        self.limit = params[:limit]
        self.offset = params[:offset]
        self.search_query = params[:search_query]
        self.search_in = params[:search_in] || DEFAULT_SEARCH_FIELDS
        self.include_warnings = params[:include_warnings] || false
      end

      def present_many
        parse_results(results)
      end

      def total
        results.first.nil? ? 0 : results.first["total"]
      end

    private

      def results
        @results ||= execute_query(ordered_fields)
      end

      def ordered_fields
        select_fields(order_and_paginate)
      end

      def full_scope
        search(join_supporting_objects(latest))
      end

      def latest
        ::Queries::GetLatest.call(self.scope.joins(:document))
      end

      def join_supporting_objects(scope)
        scope = ChangeNote.join_editions(scope)

        if fields.include? :unpublishing
          scope = Unpublishing.join_editions(scope)
        end

        scope
      end

      def order_and_paginate
        scope = full_scope
        scope = scope.order(order.to_a.join(" ")) if order
        scope = scope.limit(limit) if limit
        scope = scope.offset(offset) if offset
        scope
      end

      def select_fields(scope)
        fields_to_select = fields.map do |field|
          case field
          when :publication_state
            "editions.state AS publication_state"
          when :user_facing_version
            "editions.user_facing_version AS user_facing_version"
          when :lock_version
            "documents.stale_lock_version AS lock_version"
          when :description
            "description->>'value' AS description"
          when :last_edited_at
            "to_char(last_edited_at, '#{ISO8601_SQL}') as last_edited_at"
          when :public_updated_at
            "to_char(public_updated_at, '#{ISO8601_SQL}') as public_updated_at"
          when :first_published_at
            "to_char(first_published_at, '#{ISO8601_SQL}') as first_published_at"
          when :state_history
            "#{STATE_HISTORY_SQL} AS state_history"
          when :unpublishing
            "#{UNPUBLISHING_SQL} AS unpublishing"
          when :links
            "#{LINKS_SQL} AS links"
          when :change_note
            "change_notes.note AS change_note"
          when :base_path
            "editions.base_path as base_path"
          when :locale
            "documents.locale as locale"
          when :content_id
            "documents.content_id as content_id"
          when :total
            "COUNT(*) OVER () as total"
          else
            field
          end
        end

        scope.select(*fields_to_select)
      end

      def search(scope)
        return scope unless search_query.present?
        conditions = search_in.map { |search_field| "#{search_field} ilike :query" }
        scope.where(conditions.join(" OR "), query: "%#{search_query}%")
      end

      STATE_HISTORY_SQL = <<-SQL.freeze
        (
          SELECT json_agg((user_facing_version, state))
          FROM editions e
          WHERE e.document_id = documents.id
          GROUP BY documents.content_id
        )
      SQL

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
              unpublishings.unpublished_at
            )
          )
          AS
          unpublishing_data(
            type,
            explanation,
            alternative_path,
            unpublished_at
          )
        )
      SQL

      LINKS_SQL = <<-SQL.freeze
        (
          SELECT json_agg((links.link_type, target_content_id))
          FROM links
          WHERE links.edition_id = editions.id
          GROUP BY links.link_type
        )
      SQL

      ISO8601_SQL = "YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"".freeze

      def parse_results(results)
        json_columns = %w(details routes redirects need_ids state_history unpublishing links)
        int_columns = %w(user_facing_version lock_version)

        Enumerator.new do |yielder|
          results.each do |result|
            json_columns.each { |c| parse_json_column(result, c) }
            int_columns.each { |c| parse_int_column(result, c) }
            parse_state_history(result)
            parse_links(result)

            result["warnings"] = get_warnings(result) if include_warnings

            yielder.yield(result.except("total").compact)
          end
        end
      end

      def parse_json_column(result, column)
        return unless result.key?(column)
        result[column] = JSON.parse(result[column])
      end

      def parse_int_column(result, column)
        return unless result.key?(column)
        result[column] = result[column].to_i
      end

      def parse_links(result)
        column = "links"

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
        required_fields = %i{
          content_id
          state_history
          user_facing_version
          base_path
          document_type
        }

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
