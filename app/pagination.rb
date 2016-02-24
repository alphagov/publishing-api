class Pagination
  attr_reader :start, :page_size, :all_items

  def initialize(options={})
    if options[:start] || options[:page_size]
      @start = options[:start] ? options[:start].to_i : 0
      @page_size = options[:page_size] ? options[:page_size].to_i : 50
    else
      @all_items = true
    end
  end

  def paginate(items)
    items.limit(page_size).offset(start)
  end
end
