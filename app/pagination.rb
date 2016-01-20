class Pagination
  attr_reader :start, :count

  def initialize(options = {})
    @start = options[:start] ? options[:start].to_i : 0
    @count = options[:count] ? options[:count].to_i : 50
  end
end
