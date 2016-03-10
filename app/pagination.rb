class Pagination
  PER_PAGE = 50
  attr_reader :start, :page_size, :order

  def initialize(options = {})
    @options = options
    @order = { public_updated_at: :desc }
    @page = options[:page]
    @page_size = Integer(options.fetch(:page_size, PER_PAGE))

    @start = offset_from_page
  end

  def order_fields
    order.keys.map(&:to_s)
  end

  private
  attr_reader :options, :page

  def offset_from_page
    if page
      (page.to_i - 1) * page_size
    else
      Integer(options.fetch(:start, 0))
    end
  end
end
