# This presenter has been carefully written to run quickly. Please be careful
# if editing its behaviour and make sure to compare benchmarks.
module Presenters
  module Queries
    class ContentItemPresenter
      attr_accessor :scope, :fields, :order, :limit, :offset, :search_query,
                    :include_warnings

      DEFAULT_FIELDS = [
        *ContentItem::TOP_LEVEL_FIELDS,
        :publication_state,
        :user_facing_version,
        :base_path,
        :locale,
        :lock_version,
        :internal_name,
        :updated_at,
        :state_history,
      ].freeze

      def self.present_many(scope, params = {})
        new(scope, params).present_many
      end

      def self.present(content_item, params = {})
        scope = ContentItem.where(id: content_item.id)

        present_many(scope, params).first
      end

      def initialize(scope, params = {})
        self.scope = scope
        self.fields = (params[:fields] || DEFAULT_FIELDS).map(&:to_sym)
        self.order = params[:order]
        self.limit = params[:limit]
        self.offset = params[:offset]
        self.search_query = params[:search_query]
        self.include_warnings = params[:include_warnings] || false
      end

      def present_many
        parse_results(results)
      end

      def total
        full_scope.count
      end

    private

      def results
        execute_query(ordered_fields)
      end

      def ordered_fields
        select_fields(order_and_paginate)
      end

      def full_scope
        search(join_supporting_objects(latest))
      end

      def latest
        ::Queries::GetLatest.call(self.scope)
      end

      def join_supporting_objects(scope)
        scope = State.join_content_items(scope)
        scope = UserFacingVersion.join_content_items(scope)
        scope = Translation.join_content_items(scope)
        scope = Location.join_content_items(scope)

        LockVersion.join_content_items(scope)
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
            "states.name AS publication_state"
          when :user_facing_version
            "user_facing_versions.number AS user_facing_version"
          when :lock_version
            "lock_versions.number AS lock_version"
          when :description
            "description->>'value' AS description"
          when :internal_name
            "#{INTERNAL_NAME_SQL} AS internal_name"
          when :last_edited_at
            "to_char(last_edited_at, '#{ISO8601_SQL}') as last_edited_at"
          when :public_updated_at
            "to_char(public_updated_at, '#{ISO8601_SQL}') as public_updated_at"
          when :first_published_at
            "to_char(first_published_at, '#{ISO8601_SQL}') as first_published_at"
          when :state_history
            "#{STATE_HISTORY_SQL} AS state_history"
          else
            field
          end
        end

        scope.select(*fields_to_select)
      end

      def search(scope)
        return scope unless search_query.present?
        scope.where("title ilike ? OR base_path ilike ?", "%#{search_query}%", "%#{search_query}%")
      end

      STATE_HISTORY_SQL = <<-SQL.freeze
        (
          SELECT json_agg((number, name))
          FROM content_items c
          JOIN states s ON s.content_item_id = c.id
          JOIN user_facing_versions u ON u.content_item_id = c.id
          WHERE c.content_id = content_items.content_id
          GROUP BY content_id
        )
      SQL

      ISO8601_SQL = "YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"".freeze

      # This returns the internal_name from the details hash if it is present,
      # otherwise it falls back to the content item's title.
      INTERNAL_NAME_SQL = "COALESCE(details->>'internal_name', title) ".freeze

      def parse_results(results)
        json_columns = %w(details routes redirects need_ids state_history)
        int_columns = %w(user_facing_version lock_version)

        Enumerator.new do |yielder|
          results.each do |result|
            json_columns.each { |c| parse_json_column(result, c) }
            int_columns.each { |c| parse_int_column(result, c) }
            parse_state_history(result)

            result["warnings"] = get_warnings(result) if include_warnings

            yielder.yield result
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
