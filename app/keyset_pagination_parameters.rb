class KeysetPaginationParameters
  class << self
    def from_query(params:, default_order:, table:)
      {
        key: key(params, default_order, table),
        count: params[:per_page],
        order: order(params, default_order),
        before: params[:before].try(:split, ","),
        after: params[:after].try(:split, ","),
      }
    end

  private

    def key(params, default_order, table)
      order = params[:order] || default_order
      order = order[1..order.length] if order.first == "-"

      hash = {}
      hash[order] = "#{table}.#{order}"
      hash[:id] = "#{table}.id"
      hash
    end

    def order(params, default_order)
      order = params[:order] || default_order
      order.first == "-" ? :desc : :asc
    end
  end
end
