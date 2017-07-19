module KeysetPaginationParameters
  def self.from_query(params:, default_order:, table:)
    {
      key: self.key(params, default_order, table),
      page: params[:page].try(:split, ","),
      count: params[:per_page],
      order: self.order(params, default_order),
    }
  end

private

  def self.key(params, default_order, table)
    order = params[:order] || default_order
    order = order[1..order.length] if order.first == "-"

    hash = {}
    hash[order] = "#{table}.#{order}"
    hash[:id] = "#{table}.id"
    hash
  end

  def self.order(params, default_order)
    order = params[:order] || default_order
    order.first == "-" ? :desc : :asc
  end
end
