module Queries
  class KeysetPagination
    attr_reader :client, :order, :key, :per_page, :previous

    # Initialises the keyset pagination class.
    # Params:
    # +client+:: the pagination client to query over
    # +key+:: +Hash+ a hash containing the pagination key, mapped from presented name to internal name, i.e. { id: "editions.id" }
    # +order+:: +Symbol+ either :asc for ascending and :desc for descending
    # +per_page+:: +Fixnum+ the number of records to return in each page
    # +after+:: +Array+ the current page to paginate after, an array containing a value for each field in the key
    def initialize(client, key: nil, order: nil, per_page: nil, before:, after:)
      @client = client
      @key = key || { id: "id" }
      @order = order || :asc
      @per_page = (per_page || 100).to_i

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

      if previous.present? && previous.count != key.count
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
      KeysetPagination.new(
        client, key: key, order: order, per_page: 1,
        before: next_before_key, after: nil
      ).call.empty?
    end

    def is_last_page?
      KeysetPagination.new(
        client, key: key, order: order, per_page: 1,
        before: nil, after: next_after_key
      ).call.empty?
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
      key.keys.map do |k|
        value = record[k.to_s]
        next value.iso8601 if value.respond_to?(:iso8601)
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
      @fields ||= (presented_fields + key.keys).uniq.map(&:to_s)
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
      key.keys.each_with_object({}) { |field, hash| hash[field] = order }
    end

    def where_clause
      lhs = key.values.join(", ")
      order_character = ascending? ? ">" : "<"
      rhs = (["?"] * key.count).join(", ")
      "(#{lhs}) #{order_character} (#{rhs})"
    end
  end
end
