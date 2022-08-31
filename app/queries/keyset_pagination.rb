module Queries
  # The KeysetPagination class provides a way of implementing keyset pagination
  # on queries.
  #
  # Example usage:
  #   client = KeysetPagination::GetEditions.new
  #   query = KeysetPagination.new(client, per_page: 100, before: [10])
  #
  # The `before` and `after` parameters represent the current pagination key as
  # an array containing the last values of the previous page.
  # For example, to get the next page of a page that returned 10 items with the
  # last ID being 10, the after key would be [10]. It is an array because some
  # pagination clients may use pagination keys across multiple fields, for
  # example, `GetEditions` uses [date, id].
  class KeysetPagination
    attr_reader :client, :order, :pagination_key, :per_page, :previous

    delegate :any?, :empty?, to: :ordered_initial_results

    def initialize(client, params)
      @client = client
      @pagination_key = client.pagination_key
      @order = client.pagination_order
      @per_page = (params[:per_page] || 100).to_i

      before = params[:before]
      after = params[:after]

      if before.present? && after.present?
        raise "Before and after cannot both be present."
      end

      if before
        @previous = before
        @order = order == :asc ? :desc : :asc
        @direction = :backwards
      else
        @previous = after
        @direction = :forwards
      end

      if previous.present? && previous.count != pagination_key.count
        raise "Number of previous values does not match the number of fields."
      end
    end

    def results
      @results ||= client.post_pagination(ordered_initial_results)
    end

    def next_before_key
      key_for_record(ordered_initial_results.first)
    end

    def next_after_key
      key_for_record(ordered_initial_results.last)
    end

    def is_first_page?
      # @is_first_page ||= ordered_initial_results.empty? ||
      #   KeysetPagination.new(
      #     client, per_page: 1, before: next_before_key
      #   ).empty?
      if @is_first_page.nil?
        where = where_clause(ascending: order != :asc)
        @is_first_page = client.initial_query.where(where, *next_before_key).exists?
      end

      @is_first_page
    end

    def is_last_page?
      # @is_last_page ||= ordered_initial_results.empty? ||
      #   KeysetPagination.new(
      #     client, per_page: 1, after: next_after_key
      #   ).empty?
      if @is_last_page.nil?
        where = where_clause(ascending: order == :asc)
        @is_last_page = client.initial_query.where(where, *next_after_key).exists?
      end

      @is_last_page
    end

    def key_fields
      pagination_key.keys
    end

    def presented_fields
      client.initial_query_fields
    end

  private

    attr_reader :direction

    def key_for_record(record)
      key_fields.map do |k|
        value = record[k]
        next value.iso8601(6) if value.respond_to?(:iso8601)

        value.to_s
      end
    end

    def ordered_initial_results
      @ordered_initial_results ||= if direction == :backwards
                                     pluck_results.reverse
                                   else
                                     pluck_results
                                   end
    end

    def pluck_results
      paginated_query.pluck(*fields).map do |record|
        Hash[fields.zip(record)]
      end
    end

    def fields
      @fields ||= (presented_fields + key_fields).uniq
    end

    def paginated_query
      paginated_query = client.initial_query.order(order_clause)
      ascending = order == :asc
      paginated_query = paginated_query.where(where_clause(ascending: ascending), *previous) if previous
      paginated_query.limit(per_page)
    end

    def order_clause
      pagination_key.keys.index_with { order }
    end

    def where_clause(ascending: true)
      lhs = pagination_key.values.join(", ")
      order_character = ascending ? ">" : "<"
      rhs = (["?"] * pagination_key.count).join(", ")
      "(#{lhs}) #{order_character} (#{rhs})"
    end

    def any_previous?
      where = where_clause(ascending: order != :asc)
      client.initial_query.where(where, next_before_key).exists?
    end
  end
end
