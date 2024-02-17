LinkExpansionResult = Data.define(:edition_id, :base_path, :content_id, :link_type) do
  def to_h
    {
      edition_id:,
      base_path:,
      content_id:,
      links: {},
    }
  end
end
#
# This is the core class of Link Expansion which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/link-expansion.md
#
class FastLinkExpansion
  def self.by_edition(edition, with_drafts: false)
    new(edition:, with_drafts:)
  end

  def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
    new(content_id:, locale:, with_drafts:)
  end

  def initialize(options)
    @options = options
    @with_drafts = options.fetch(:with_drafts)
  end

  def links_with_content
    # TODO - alias the results from root_links and level_1_links so they're consistent
    # and can be joined with reverse links and edition links

    root_links = Link.joins(:link_set).where(link_sets: { content_id: })
    root_linked_editions = linked_editions(root_links)
    level_1_condition = link_type_condition(root_linked_editions)
    level_1_links = Link.joins(:link_set).where(level_1_condition)
    level_1_linked_editions = linked_editions(level_1_links)

    # TODO - knit the level 1 links into the links: [] arrays in the root links
    # instead of flattening them 👇
    (root_linked_editions + level_1_linked_editions).group_by(&:link_type)
      .transform_values { |g| g.map(&:to_h) }
      .transform_keys(&:to_sym)
  end

private

  attr_reader :options, :with_drafts

  def edition
    @edition ||= options[:edition]
  end

  def content_id
    edition ? edition.content_id : options.fetch(:content_id)
  end

  def linked_editions(level_links)
    Edition
      .with_document
      .with(level_links:)
      .joins("INNER JOIN level_links ON level_links.target_content_id = documents.content_id")
      .where(state: "draft") # TODO - more states
      .where(documents: { locale: "en" }) # TODO - more locales
      .where.not(document_type: Edition::NON_RENDERABLE_FORMATS)
      .pluck(
        :id,
        :base_path,
        "documents.content_id",
        "level_links.link_type",
      )
      .map { |row| LinkExpansionResult.new(*row) }
  end

  def link_type_condition(linked_editions)
    links_table = Link.arel_table
    link_sets_table = LinkSet.arel_table

    # TODO - need to remove the link types that don't match the expansion rules
    linked_editions.group_by(&:link_type)
      .map { |link_type, links|
        links_table[:link_type].eq(link_type).and(
          link_sets_table[:content_id].in(links.map(&:content_id).uniq),
        )
      }.reduce(:or)
  end
end
