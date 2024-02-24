#
# This is the core class of Link Expansion which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/link-expansion.md

# TODO - use sequel-rails to configure this properly
# TODO - how to integrate this with FactoryBot??
DB = Sequel.connect(Rails.configuration.database_configuration[Rails.env])

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
    ds = DB[:links].with(
      Sequel.lit("previous_links(link_type, content_id)"),
      DB.values([[nil, Sequel.cast(content_id, "uuid")]]),
    )

    root_links = link_set_links(ds)
      .union(reverse_link_set_links, from_self: false)
      .union(edition_links, from_self: false)
      .union(reverse_edition_links, from_self: false)

    ds = DB[:links]
      .with(
        Sequel.lit("previous_links(link_type, content_id)"),
        # TODO - we don't want the previous link type here, we want the next link types
        DB.values(root_links.all.map { |l| [l[:link_type], Sequel.cast(l[:content_id], "uuid")] }),
      )
    level_1_links = link_set_links(ds)
      .union(reverse_link_set_links, from_self: false)
      .union(edition_links, from_self: false)
      .union(reverse_edition_links, from_self: false)

    root_linked_editions = DB[:editions]
      .join(:documents, id: :document_id)
      .with(:root_links, root_links)
      .join(:root_links, target_content_id: Sequel[:documents][:content_id])
      .where(
        Sequel[:editions][:state] => "published", # TODO more states
        Sequel[:documents][:locale] => "en", # TODO more locales
      )
      .select(
        Sequel[:editions][:id].as(:edition_id),
        Sequel[:editions][:base_path].as(:base_path),
        Sequel[:documents][:content_id].as(:content_id),
        Sequel[:root_links][:link_type].as(:the_link_type),
        # TODO paths
      )
      .all
    return {} if root_linked_editions.empty?

    level_1_links = DB[:links]
      .with(
        Sequel.lit("previous_links(edition_id, base_path, content_id, the_link_type)"),
        DB.values(root_linked_editions.map do
                    [
                      _1[:edition_id],
                      _1[:base_path],
                      Sequel.cast(_1[:content_id], "uuid"),
                      _1[:the_link_type],
                    ]
                  end),
      )
      .join(:link_sets, id: :link_set_id)
      .join(:previous_links, the_link_type: Sequel[:links][:link_type], content_id: Sequel[:link_sets][:content_id])

    level_1_linked_editions = DB[:editions]
      .join(:documents, id: :document_id)
      .with(:level_1_links, level_1_links)
      .join(:level_1_links, target_content_id: Sequel[:documents][:content_id])
      .where(
        Sequel[:editions][:state] => "published", # TODO more states
        Sequel[:documents][:locale] => "en", # TODO more locales
      )
      .select(
        Sequel[:editions][:id].as(:edition_id),
        Sequel[:editions][:base_path].as(:base_path),
        Sequel[:documents][:content_id].as(:content_id),
        Sequel[:level_1_links][:link_type].as(:the_link_type),
        # TODO paths
      )
      .all

    # TODO: - knit the level 1 links into the links: [] arrays in the root links
    # instead of flattening them 👇
    (root_linked_editions + level_1_linked_editions).group_by { |x| x[:the_link_type] }
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

  def link_set_links(dataset = DB[:links])
    dataset
      .join(:link_sets, id: :link_set_id)
      .join(:previous_links, content_id: Sequel[:link_sets][:content_id])
      .where(Sequel.or([
        [Sequel[:previous_links][:link_type], nil],
        [Sequel[:previous_links][:link_type], Sequel[:links][:link_type]],
      ]))
      .select(Sequel[:links][:link_type], :target_content_id)
  end

  def reverse_link_set_links
    DB[:links]
      .join(:link_sets, id: :link_set_id)
      .join(:previous_links, content_id: Sequel[:links][:target_content_id])
      .where(Sequel.or([
        [Sequel[:previous_links][:link_type], nil],
        [Sequel[:previous_links][:link_type], Sequel[:links][:link_type]],
      ]))
      .where(Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s))
      .select(Sequel[:links][:link_type], Sequel[:link_sets][:content_id])
  end

  def edition_links
    DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:previous_links, content_id: Sequel[:documents][:content_id])
      .where(Sequel.or([
        [Sequel[:previous_links][:link_type], nil],
        [Sequel[:previous_links][:link_type], Sequel[:links][:link_type]],
      ]))
      .where(
        Sequel[:documents][:locale] => "en", # TODO more locales
        Sequel[:editions][:content_store] => "live", # TODO more content stores
      ).select(Sequel[:links][:link_type], :target_content_id)
  end

  def reverse_edition_links
    DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:previous_links, content_id: Sequel[:links][:target_content_id])
      .where(Sequel.or([
        [Sequel[:previous_links][:link_type], nil],
        [Sequel[:previous_links][:link_type], Sequel[:links][:link_type]],
      ]))
      .where(
        Sequel[:documents][:locale] => "en", # TODO more locales
        Sequel[:editions][:content_store] => "live", # TODO more content stores
        Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s),
      ).select(Sequel[:links][:link_type], Sequel[:documents][:content_id])
  end
end
