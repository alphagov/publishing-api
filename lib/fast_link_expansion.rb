LinkExpansionResult = Data.define(
  :edition_id,
  :base_path,
  :content_id,
  :link_type,
  :content_id_path,
  :link_type_path,
) do
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
    # TODO: - alias the results from root_links and level_1_links so they're consistent
    # and can be joined with reverse links and edition links

    root_links = Link.joins(:link_set).where(link_sets: { content_id: })
    root_linked_editions = Edition
      .with_document
      .with(root_links:)
      .joins("INNER JOIN root_links ON root_links.target_content_id = documents.content_id")
      .where(state: "draft") # TODO: - more states
      .where(documents: { locale: "en" }) # TODO: - more locales
      .where.not(document_type: Edition::NON_RENDERABLE_FORMATS)
      .pluck(
        :id,
        :base_path,
        "documents.content_id",
        "root_links.link_type",
        Arel.sql('ARRAY["documents"."content_id"]'),
        Arel.sql('ARRAY["root_links"."link_type"]'),
      )
      .map { |row| LinkExpansionResult.new(*row) }

    link_type_condition(root_linked_editions)

    # TODO this is pretty filthy
    values = Arel::Nodes::ValuesList.new(
      root_linked_editions.map do |e|
        [
          Arel.sql("'#{e.content_id}'::uuid"),
          e.link_type,
          Arel.sql("Array[#{e.content_id_path.map { |x| "'#{x}'" }.join(',')}]"),
          Arel.sql("Array[#{e.link_type_path.map { |x| "'#{x}'" }.join(',')}]"),
        ]
      end,
    )
    as = Arel::Nodes::As.new(
      Arel::Nodes::Grouping.new(values),
      Arel.sql("prev_values(content_id, link_type, content_id_path, link_type_path)"),
    )
    previous_links = Arel::Table.new(:prev_values).project(Arel.star).from(as)

    level_1_links = Link
      .with(previous_links:)
      .joins(:link_set)
      .joins("INNER JOIN previous_links ON previous_links.link_type = links.link_type AND previous_links.content_id = link_sets.content_id")

    level_1_linked_editions = Edition
       .with_document
       .with(level_1_links:)
       .joins("INNER JOIN level_1_links ON level_1_links.target_content_id = documents.content_id")
       .where(state: "draft") # TODO: - more states
       .where(documents: { locale: "en" }) # TODO: - more locales
       .where.not(document_type: Edition::NON_RENDERABLE_FORMATS)
       .pluck(
         :id,
         :base_path,
         "documents.content_id",
         "level_1_links.link_type",
         Arel.sql('ARRAY["documents"."content_id"]'), # TODO: this needs to include more stuff
         Arel.sql('ARRAY["level_1_links"."link_type"]'), # TODO: this needs to include more stuff
       )
       .map { |row| LinkExpansionResult.new(*row) }

    # TODO: - knit the level 1 links into the links: [] arrays in the root links
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

  # TODO: factor this out and unit test it
  def link_type_condition(linked_editions)
    link_type_col = Link.arel_table[:link_type]
    content_id_col = LinkSet.arel_table[:content_id]

    # TODO
    # For each link_type_path, we need to join it with the link expansion rules
    # to work out what the possible child link types for this path are.
    # It's these possible child link types that we need to use in this condition,
    # not the link types we're using right now.

    linked_editions
      .group_by(&:link_type)
      .transform_values { |links| links.map(&:content_id).uniq }
      .map { |link_type, content_ids| link_type_col.eq(link_type).and(content_id_col.in(content_ids)) }
      .reduce(:or)
  end
end
