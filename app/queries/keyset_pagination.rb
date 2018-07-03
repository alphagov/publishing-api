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

    def call
      results
    end

    def next_before_key
      key_for_record(results.first)
    end

    def next_after_key
      key_for_record(results.last)
    end

    def is_first_page?
      @is_first_page ||= results.empty? ||
        KeysetPagination.new(
          client, per_page: 1, before: next_before_key
        ).call.empty?
    end

    def is_last_page?
      @is_last_page ||= results.empty? ||
        KeysetPagination.new(
          client, per_page: 1, after: next_after_key
        ).call.empty?
    end

    def key_fields
      pagination_key.keys.map(&:to_s)
    end

    def presented_fields
      client.fields
    end

  private

    attr_reader :direction

    def results
      @results ||= ordered_results
    end

    def key_for_record(record)
      key_fields.map do |k|
        value = record[k]
        next value.iso8601(6) if value.respond_to?(:iso8601)
        value.to_s
      end
    end

    def ordered_results
      if direction == :backwards
        plucked_results.reverse
      else
        plucked_results
      end
    end

    def plucked_results
      paginated_query.pluck(*fields).map do |record|
        Hash[fields.zip(record)]
      end
    end

    def fields
      @fields ||= (presented_fields + key_fields).uniq
    end

    def paginated_query
      paginated_query = client.call.order(order_clause)
      paginated_query = paginated_query.where(where_clause, *previous) if previous
      paginated_query.limit(per_page)
    end

    def ascending?
      order == :asc
    end

    def order_clause
      pagination_key.keys.each_with_object({}) do |field, hash|
        hash[field] = order
      end
    end

    def where_clause
      lhs = pagination_key.values.join(", ")
      order_character = ascending? ? ">" : "<"
      rhs = (["?"] * pagination_key.count).join(", ")
      "(#{lhs}) #{order_character} (#{rhs})"
    end
  end
end
