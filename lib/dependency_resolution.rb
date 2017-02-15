class DependencyResolution
  attr_reader :content_id, :with_drafts

  def initialize(content_id, with_drafts)
    @content_id = content_id
    @with_drafts = with_drafts
  end

  def dependencies
    link_graph.links_content_ids
  end

  def link_graph
    @link_graph ||= LinkGraph.new(content_id, nil, with_drafts, LinkReference.new)
  end
end
