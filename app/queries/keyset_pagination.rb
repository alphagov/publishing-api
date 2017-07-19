module Queries
  class KeysetPagination
    attr_reader :client, :order, :key, :count, :previous

    # Initialises the keyset pagination class.
    # Params:
    # +client+:: the pagination client to query over
    # +key+:: +Hash+ a hash containing the pagination key, mapped from presented name to internal name, i.e. { id: "editions.id" }
    # +order+:: +Symbol+ either :asc for ascending and :desc for descending
    # +count+:: +Fixnum+ the number of records to return in each page
    # +after+:: +Array+ the current page to paginate after, an array containing a value for each field in the key
    def initialize(client, key: nil, order: nil, count: nil, before:, after:)
      @client = client
      @key = key || { id: "id" }
      @order = order || :asc
      @count = (count || 100).to_i

      if before.present? && after.present?
        raise "Before and after cannot both be present."
      end

      if before
        @previous = before
        @order = order == :asc ? :desc : asc
        @presenter_should_reverse = true
      else
        @previous = after
        @presenter_should_reverse = false
      end

      if previous.present? && previous.count != key.count
        raise "Number of previous values does not match the number of fields."
      end
    end

    def call
      if presenter_should_reverse
        results.reverse
      else
        results
      end
    end

    def key_for_record(record)
      values = key.keys.map do |k|
        value = record[k.to_s]
        next value.iso8601 if value.respond_to?(:iso8601)
        value.to_s
      end
      values.join(",")
    end

  private

    attr_reader :presenter_should_reverse

    def pluck_to_hash(query, keys)
      query.pluck(*keys).map do |record|
        Hash[keys.zip(record)]
      end
    end

    def results
      pluck_to_hash(paginated_query, fields)
    end

    def fields
      (client.fields + key.keys).uniq.map(&:to_s)
    end

    def paginated_query
      paginated_query = client.call.order(order_clause)
      paginated_query = paginated_query.where(where_clause, *previous) if previous
      paginated_query.limit(count)
    end

    def ascending?
      order == :asc
    end

    def descending?
      order == :desc
    end

    def order_clause
      key.keys.each_with_object({}) { |field, hash| hash[field] = order }
    end

    def order_character
      ascending? ? ">" : "<"
    end

    def where_clause_lhs
      key.values.join(", ")
    end

    def where_clause_rhs
      (["?"] * key.count).join(", ")
    end

    def where_clause
      "(#{where_clause_lhs}) #{order_character} (#{where_clause_rhs})"
    end
  end
end
