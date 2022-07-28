#
# This is the core class of Dependency Resolution which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/dependency-resolution.md
#
class DependencyResolution
  attr_reader :content_id, :locale, :with_drafts

  def initialize(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    @content_id = content_id
    @locale = locale
    @with_drafts = with_drafts
  end

  def dependencies
    link_graph.links_content_ids
  end

  def link_graph
    @link_graph ||= LinkGraph.new(
      root_content_id: content_id,
      root_locale: locale,
      with_drafts:,
      link_reference: LinkReference.new,
    )
  end
end
