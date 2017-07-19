module Queries
  class KeysetPagination
    attr_reader :query, :order, :key, :count, :previous, :presenter_should_reverse

    # Initialises the keyset pagination class.
    # Params:
    # +query+:: the query to paginate
    # +key+:: +Hash+ a hash containing the pagination key, mapped from presented name to internal name, i.e. { id: "editions.id" }
    # +order+:: +Symbol+ either :asc for ascending and :desc for descending
    # +count+:: +Fixnum+ the number of records to return in each page
    # +after+:: +Array+ the current page to paginate after, an array containing a value for each field in the key
    def initialize(query, key: nil, order: nil, count: nil, before:, after:)
      @query = query
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
      paginated_query = query.order(order_clause)
      paginated_query = paginated_query.where(where_clause, *previous) if previous
      paginated_query.limit(count)
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
