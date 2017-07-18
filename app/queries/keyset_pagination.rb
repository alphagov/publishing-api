module Queries
  class KeysetPagination
    attr_reader :query, :key, :count, :previous, :order

    def initialize(query, key: nil, count: nil, before:, after:)
      @query = query
      @key = (key || DEFAULT_KEY)
      @count = (count || DEFAULT_COUNT).to_i

      if before.present? && after.present?
        raise "Cannot set both before and after."
      end

      @previous = before ? before : after
      @order = before ? :desc : :asc

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
        if value.instance_of?(ActiveSupport::TimeWithZone)
          value.iso8601
        else
          value
        end
      end
      values.join(",")
    end

    def presenter_should_reverse_results?
      descending?
    end

  private

    DEFAULT_KEY = ["id"].freeze
    DEFAULT_COUNT = 100

    def ascending?
      order == :asc
    end

    def descending?
      order == :desc
    end

    def order_clause(order: nil)
      order ||= @order
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
