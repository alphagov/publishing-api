#
# Entry point for Dependency Resolution, which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/dependency-resolution.md
#
# This is a thin entry point; the traversal itself lives in
# DependencyResolution::BreadthFirstResolver.
#
class DependencyResolution
  def initialize(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    @resolver = DependencyResolution::BreadthFirstResolver.new(
      content_id,
      locale:,
      with_drafts:,
    )
  end

  delegate :dependencies, to: :@resolver
end
