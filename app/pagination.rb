class Pagination
  PER_PAGE = 50
  attr_reader :offset, :per_page, :order, :page

  def initialize(options = {})
    @options = options
    @order = { public_updated_at: :desc }
    @page = options[:page] || 1
    @per_page = options.fetch(:per_page, PER_PAGE).to_i

    @offset = offset_from_page
  end

  def order_fields
    order.keys.map(&:to_s)
  end

  def pages(total)
    (total.to_f / per_page).ceil
  end

private

  attr_reader :options

  def offset_from_page
    options.fetch(:offset, (page.to_i - 1) * per_page).to_i
  end
end
