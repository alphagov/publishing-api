class Pagination
  attr_reader :start, :page_size, :all_items, :order

  def initialize(options = {})
    @order = { public_updated_at: :desc }

    if options[:start] || options[:page_size]
      @start = Integer(options.fetch(:start, 0))
      @page_size = Integer(options.fetch(:page_size, 50))
    else
      @all_items = true
    end
  end

  def paginate(items)
    unless all_items
      items = items.limit(page_size).offset(start)
    end
    items
  end

  def order_fields
    order.keys.map(&:to_s)
  end
end
