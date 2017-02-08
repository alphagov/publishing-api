class DependencyResolution
  attr_reader :content_id

  def initialize(content_id)
    @content_id = content_id
  end

  def dependencies
    link_graph.links_content_ids
  end

  def link_graph
    @link_graph ||= LinkGraph.new(content_id, LinkReference.new)
  end
end
