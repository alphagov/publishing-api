#
# This is the core class of Link Expansion which is a complicated concept
# in the Publishing API
#
# The concept is documented in /docs/link-expansion.md

# TODO - use sequel-rails to configure this properly
# TODO - how to integrate this with FactoryBot??

Sequel.extension :pg_array, :pg_array_ops
DB = Sequel.connect(Rails.configuration.database_configuration[Rails.env])
DB.extension :pg_array

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
    root_content_id_uuid = Sequel.cast(content_id, "uuid")
    # Supply a list of parents as a CTE
    # This will produce SQL like:
    #     WITH "parents" AS (VALUES ('cafebabe-cafe-babe-face-cafebabeface'::uuid)),
    #          "parents_reverse" AS (VALUES ('person', 'cafebabe...'), ...)
    #     SELECT * from "links"
    # For the root case we pass the root content_id as the only value - it's a special case because
    # all link types are valid at the root level.
    #
    # For subsequent levels of depth, we pass the content_ids of all the children, along with the allowed link types
    # for the next level of depth from there.
    # TODO - add paths to these, and everywhere they're used
    parents_ds = DB[:links].with(
      Sequel.lit("parents(content_id, link_type_path, content_id_path)"),
      DB.values([[
        root_content_id_uuid,
        Sequel.pg_array([], "text"),
        Sequel.pg_array([], "uuid"),
      ]]),
    ).with(
      Sequel.lit("parents_reverse(link_type, content_id, link_type_path, content_id_path)"),
      DB.values(ExpansionRules.reverse_links.map do |link|
        [
          link.to_s,
          root_content_id_uuid,
          Sequel.pg_array([], "text"),
          Sequel.pg_array([], "uuid"),
        ]
      end),
    )

    root_links_ds = link_set_links(parents_ds, root_level: true)
      .union(reverse_link_set_links, from_self: false)
      .union(edition_links(root_level: true), from_self: false)
      .union(reverse_edition_links, from_self: false)

    root_links = root_links_ds.pluck(:link_type, :content_id, :link_type_path, :content_id_path)
    next_direct_links = root_links.flat_map { |link_type, content_id, link_type_path, content_id_path|
      allowed_link_types = allowed_direct_link_types([link_type.to_sym])
      allowed_link_types.map { [_1.to_s, content_id, link_type_path, content_id_path] }
    }.uniq
    next_reverse_links = root_links.flat_map { |link_type, content_id, link_type_path, content_id_path|
      allowed_link_types = allowed_reverse_link_types([link_type.to_sym])
      allowed_link_types.map { [_1.to_s, content_id, link_type_path, content_id_path] }
    }.uniq

    parents_ds = DB[:links]
      .with(
        Sequel.lit("parents(link_type, content_id, link_type_path, content_id_path)"),
        DB.values(next_direct_links.map do |link_type, content_id, link_type_path, content_id_path|
          [
            link_type,
            Sequel.cast(content_id, "uuid"),
            link_type_path,
            content_id_path,
          ]
        end),
      )
      .with(
        Sequel.lit("parents_reverse(link_type, content_id, link_type_path, content_id_path)"),
        DB.values(next_reverse_links.map do |link_type, content_id, link_type_path, content_id_path|
          [
            link_type,
            Sequel.cast(content_id, "uuid"),
            link_type_path,
            content_id_path,
          ]
        end),
      )

    level_1_links_ds = link_set_links(parents_ds)
      .union(reverse_link_set_links, from_self: false)
      # .union(edition_links, from_self: false)
      # .union(reverse_edition_links)

    level_1_links = level_1_links_ds.pluck(:link_type, :content_id, :link_type_path, :content_id_path)

    # TODO - draw the rest of the owl
    level_1_links
  end

private

  attr_reader :options, :with_drafts

  def edition
    @edition ||= options[:edition]
  end

  def content_id
    edition ? edition.content_id : options.fetch(:content_id)
  end

  def allowed_direct_link_types(link_types_path)
    @multi_level_links.allowed_link_types(link_types_path).reject do |link_type|
      ExpansionRules.is_reverse_link_type?(link_type)
    end
  end

  def allowed_reverse_link_types(link_types_path)
    @multi_level_links.allowed_link_types(link_types_path).select do |link_type|
      ExpansionRules.is_reverse_link_type?(link_type)
    end
  end

  def link_set_links(dataset = DB[:links], root_level: false)
    ds = dataset
      .join(:link_sets, id: :link_set_id)
      .join(:parents, content_id: Sequel[:link_sets][:content_id])

    ds = ds.where(Sequel[:parents][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.select(
      Sequel[:links][:link_type],
      Sequel[:target_content_id].as(:content_id),
      Sequel[:link_type_path].pg_array.push(Sequel[:links][:link_type]).as(:link_type_path),
      Sequel[:content_id_path].pg_array.push(Sequel[:target_content_id]).as(:content_id_path),
    )
  end

  def reverse_link_set_links
    DB[:links]
      .join(:link_sets, id: :link_set_id)
      .join(:parents_reverse, content_id: Sequel[:links][:target_content_id], link_type: Sequel[:links][:link_type])
      .where(Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s))
      .select(
        Sequel[:links][:link_type],
        Sequel[:link_sets][:content_id],
        Sequel[:link_type_path].pg_array.push(Sequel[:links][:link_type]).as(:link_type_path),
        Sequel[:content_id_path].pg_array.push(Sequel[:link_sets][:content_id]).as(:content_id_path),
      )
  end

  def edition_links(root_level: false)
    ds = DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:parents, content_id: Sequel[:documents][:content_id])

    ds = ds.where(Sequel[:parents][:link_type] => Sequel[:links][:link_type]) unless root_level

    ds.where(
      Sequel[:documents][:locale] => "en", # TODO more locales
      Sequel[:editions][:content_store] => "live", # TODO more content stores
    ).select(
      Sequel[:links][:link_type],
      Sequel[:target_content_id].as(:content_id),
      Sequel[:link_type_path].pg_array.push(Sequel[:links][:link_type]).as(:link_type_path),
      Sequel[:content_id_path].pg_array.push(Sequel[:target_content_id]).as(:content_id_path),
    )
  end

  def reverse_edition_links
    DB[:links]
      .join(:editions, id: :edition_id)
      .join(:documents, id: :document_id)
      .join(:parents_reverse, content_id: Sequel[:links][:target_content_id], link_type: Sequel[:links][:link_type])
      .where(
        Sequel[:documents][:locale] => "en", # TODO more locales
        Sequel[:editions][:content_store] => "live", # TODO more content stores
        Sequel[:links][:link_type] => ExpansionRules.reverse_links.map(&:to_s),
      )
      .select(
        Sequel[:links][:link_type],
        Sequel[:documents][:content_id],
        Sequel[:link_type_path].pg_array.push(Sequel[:links][:link_type]).as(:link_type_path),
        Sequel[:content_id_path].pg_array.push(Sequel[:documents][:content_id]).as(:content_id_path),
      )
  end
end
