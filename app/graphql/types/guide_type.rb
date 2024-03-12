# frozen_string_literal: true

module Types
  class GuideType < Types::EditionType
    description "A guide"
    field :parts, [PartType] do
      argument :slug, String, required: false
    end
    field :mainstream_browse_pages, [EditionType]
    field :related_items, [EditionType] do
      argument :first, Integer
    end

    def parts(slug: nil)
      all_parts = object.details.deep_stringify_keys.fetch("parts", [])
      slug.present? ? all_parts.filter { _1["slug"] == slug } : all_parts
    end

    def mainstream_browse_pages
      content_ids = dataloader
                      .with(Sources::LinkSetLinksFromSource, %i[mainstream_browse_pages])
                      .load(object.content_id)
                      .map(&:target_content_id)
      dataloader.with(Sources::EditionSource).load_all(content_ids)
    end

    def related_items(first: nil)
      content_ids = dataloader
        .with(Sources::LinkSetLinksFromSource, %i[ordered_related_items])
        .load(object.content_id)
        .map(&:target_content_id)

      if first.present?
        content_ids = content_ids.take(first)
      end

      dataloader.with(Sources::EditionSource).load_all(content_ids)
    end
  end
end
