module Queries
  class KeysetPagination
    attr_reader :query, :order, :key, :count, :page

    def initialize(query, key: nil, order: nil, count: nil, page:)
      @query = query
      @key = key || DEFAULT_KEY
      @order = order || DEFAULT_ORDER
      @count = (count || DEFAULT_COUNT).to_i
      @page = page

      if page.present? && page.count != key.count
        raise "Number of previous values does not match the number of fields."
      end
    end

    def call
      paginated_query = query.order(order_clause)
      paginated_query = paginated_query.where(where_clause, *page) if page
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

  private

    DEFAULT_KEY = ["id"].freeze
    DEFAULT_COUNT = 100
    DEFAULT_ORDER = :asc

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
