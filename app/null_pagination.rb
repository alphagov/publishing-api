class NullPagination
  extend Forwardable

  def_delegators :@pagination, :order, :order_fields

  def initialize
    @pagination = Pagination.new
  end

  def offset
    0
  end

  def per_page; end
end
