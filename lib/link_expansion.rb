#
# Entry point for Link Expansion, which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/link-expansion.md
#
# This is a thin entry point; the traversal itself lives in
# LinkExpansion::BreadthFirstExpander.
#
class LinkExpansion
  def self.by_edition(edition, with_drafts: false)
    new(edition:, with_drafts:)
  end

  def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    new(content_id:, locale:, with_drafts:)
  end

  delegate :links_with_content, to: :breadth_first_expander

  def initialize(options)
    @options = options
    @with_drafts = options.fetch(:with_drafts)
  end

private

  attr_reader :options, :with_drafts

  def breadth_first_expander
    @breadth_first_expander ||= LinkExpansion::BreadthFirstExpander.new(
      edition: options[:edition],
      content_id: options[:content_id],
      locale: options[:edition] ? nil : options[:locale],
      with_drafts:,
    )
  end
end
