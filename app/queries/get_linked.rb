module Queries
  class GetLinked
    attr_reader :target_content_id, :link_type, :fields

    def initialize(content_id:, link_type:, fields:)
      @target_content_id = content_id
      @link_type = link_type
      @fields = fields
    end

    def call
      validate_presence_of_item!
      validate_fields!

      content_items.map do |content_item|
        hash = Presenters::Queries::ContentItemPresenter.new(
          content_item,
          draft_versions[content_item.id],
          live_versions[content_item.live_content_item.try(:id)]
        )
        hash.present.as_json(only: output_fields)
      end
    end

  private

    attr_reader :live_versions, :draft_versions

    def validate_presence_of_item!
      return if DraftContentItem.exists?(content_id: target_content_id) ||
                LiveContentItem.exists?(content_id: target_content_id)


      raise CommandError.new(code: 404, error_details: {
        error: {
          code: 404,
          message: "No item with content_id: '#{target_content_id}'"
        }
      })
    end

    def validate_fields!
      invalid_fields = fields - permitted_fields
      return if invalid_fields.empty? && fields.any?

      if fields.empty?
        code = 422
        message = "Fields must be provided"
      else
        code = 400
        message = "Invalid column field(s): #{invalid_fields.to_sentence}"
      end

      raise CommandError.new(code: code, error_details: {
        error: {
          code: code,
          message: message
        }
      })
    end

    def content_items
      content_ids = Link.select("link_sets.content_id")
                      .joins(:link_set)
                      .where(target_content_id: target_content_id, link_type: link_type)

      draft_items = DraftContentItem.includes(:live_content_item).where(content_id: content_ids)

      live_items_without_draft = LiveContentItem
                                  .where(content_id: content_ids)
                                  .where.not(content_id: draft_items.map(&:content_id))

      @draft_versions = Version.in_bulk(draft_items, DraftContentItem)
      @live_versions = Version.in_bulk(
        draft_items.map(&:live_content_item) + live_items_without_draft, LiveContentItem
      )

      draft_items + live_items_without_draft
    end

    def output_fields
      fields.map(&:to_sym) << :publication_state
    end

    def permitted_fields
      DraftContentItem.column_names
    end
  end
end
