class Pagination
  PER_PAGE = 50
  attr_reader :offset, :per_page, :order

  def initialize(options = {})
    @options = options
    @order = { public_updated_at: :desc }
    @page = options[:page]
    @per_page = options.fetch(:per_page, PER_PAGE).to_i

    @offset = offset_from_page
  end

  def order_fields
    order.keys.map(&:to_s)
  end

private

  attr_reader :options, :page

  def offset_from_page
    if page
      (page.to_i - 1) * per_page
    else
      options.fetch(:offset, 0).to_i
    end
  end
end
