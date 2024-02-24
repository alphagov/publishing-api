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
    @multi_level_links = ExpansionRules::MultiLevelLinks.new(
      ExpansionRules::MULTI_LEVEL_LINK_PATHS,
    )
  end

  def links_with_content
    # Supply a list of parents as a CTE
    # This will produce SQL like:
    #     WITH "previous_links" AS (VALUES ('cafebabe-cafe-babe-face-cafebabeface'::uuid))
    #     SELECT * from "links"
    # For the root case we pass the root content_id as the only value - it's a special case because
    # all link types are valid at the root level.
    #
    # For subsequent levels of depth, we pass the content_ids of all the children, along with the allowed link types
    # for the next level of depth from there.
    previous_links_ds = DB[:links].with(
      Sequel.lit("previous_links(content_id)"),
      DB.values([[Sequel.cast(content_id, "uuid")]]),
    )

    root_links_ds = link_set_links(previous_links_ds, root_level: true)
      .union(reverse_link_set_links(root_level: true), from_self: false)
      .union(edition_links(root_level: true), from_self: false)
      .union(reverse_edition_links(root_level: true), from_self: false)

    root_links = root_links_ds.pluck(:link_type, :content_id)
    next_links = root_links.flat_map { |link_type, content_id|
      allowed_link_types = @multi_level_links.allowed_link_types([link_type.to_sym])
      allowed_link_types.map { [_1.to_s, content_id] }
    }.uniq

    previous_links_ds = DB[:links]
      .with(
        Sequel.lit("previous_links(link_type, content_id)"),
        DB.values(next_links.map { |link_type, content_id| [link_type, Sequel.cast(content_id, "uuid")] }),
      )
    level_1_links_ds = link_set_links(previous_links_ds)
      .union(reverse_link_set_links, from_self: false)
      .union(edition_links, from_self: false)
      .union(reverse_edition_links, from_self: false)

    level_1_links = level_1_links_ds.pluck(:link_type, :content_id)

    # TODO - draw the rest of the owl
  end

private

  attr_reader :options, :with_drafts

  def edition
    @edition ||= options[:edition]
  end

  def content_id
    edition ? edition.content_id : options.fetch(:content_id)
  end

  def link_set_links(dataset = DB[:links], root_level: false)
    ds = dataset
      .join(:link_sets, id: :link_set_id)
      .join(:previous_links, content_id: Sequel[:link_sets][:content_id])

    ds = ds.where(Sequel[:previous_links][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.select(Sequel[:links][:link_type], Sequel[:target_content_id].as(:content_id))
  end

  def reverse_link_set_links(root_level: false)
    ds = DB[:links]
      .join(:link_sets, id: :link_set_id)
      .join(:previous_links, content_id: Sequel[:links][:target_content_id])

    # TODO - does this need to be different for reverse links?
    ds = ds.where(Sequel[:previous_links][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.where(Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s))
      .select(Sequel[:links][:link_type], Sequel[:link_sets][:content_id])
  end

  def edition_links(root_level: false)
    ds = DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:previous_links, content_id: Sequel[:documents][:content_id])

    ds = ds.where(Sequel[:previous_links][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.where(
      Sequel[:documents][:locale] => "en", # TODO more locales
      Sequel[:editions][:content_store] => "live", # TODO more content stores
    ).select(Sequel[:links][:link_type], Sequel[:target_content_id].as(:content_id))
  end

  def reverse_edition_links(root_level: false)
    ds = DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:previous_links, content_id: Sequel[:links][:target_content_id])

    # TODO - does this need to be different for reverse links?
    ds = ds.where(Sequel[:previous_links][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.where(
      Sequel[:documents][:locale] => "en", # TODO more locales
      Sequel[:editions][:content_store] => "live", # TODO more content stores
      Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s),
    ).select(Sequel[:links][:link_type], Sequel[:documents][:content_id])
  end
end
