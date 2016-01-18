module Queries
  class GetContentCollection
    attr_reader :content_format, :fields

    def initialize(content_format:, fields:, publishing_app: nil, pagination: Pagination.new)
      @content_format = content_format
      @fields = fields
      @publishing_app = publishing_app
      @pagination = pagination
    end

    def call
      validate_fields!

      content_items.map do |content_item|
        hash = Presenters::Queries::ContentItemPresenter.new(
          content_item,
          draft_version(content_item),
          live_version(content_item)
        )
        hash.present.as_json(only: output_fields)
      end
    end

  private

    attr_reader :live_versions, :draft_versions, :pagination

    def content_items
      draft_items = DraftContentItem
        .includes(:live_content_item)
        .where(format: [content_format, "placeholder_#{content_format}"])
        .select(*fields + %i[id content_id])
        .limit(pagination.count).offset(pagination.start)

      draft_items = draft_items.where(publishing_app: @publishing_app) if @publishing_app.present?

      live_count = pagination.count - draft_items.length
      live_start = draft_items.any? ? 0 : pagination.start

      live_items = LiveContentItem
        .where.not(content_id: draft_items.map(&:content_id))
        .where(format: [content_format, "placeholder_#{content_format}"])
        .select(*fields + %i[id])
        .limit(live_count).offset(live_start)

      live_items = live_items.where(publishing_app: @publishing_app) if @publishing_app.present?

      @draft_versions = Version.in_bulk(draft_items, DraftContentItem)
      @live_versions = Version.in_bulk(
        draft_items.map(&:live_content_item) + live_items, LiveContentItem
      )
      draft_items + live_items
    end

    def validate_fields!
      invalid_fields = fields - permitted_fields
      return unless invalid_fields.any?

      raise CommandError.new(code: 400, error_details: {
        error: {
          code: 400,
          message: "Invalid column name(s): #{invalid_fields.to_sentence}"
        }
      })
    end

    def output_fields
      fields.map(&:to_sym) << :publication_state
    end

    def permitted_fields
      DraftContentItem.column_names
    end

    def draft_version(item)
      case item
      when DraftContentItem
        @draft_versions[item.id]
      when LiveContentItem
        @draft_versions[item.draft_content_item.try(:id)]
      end
    end

    def live_version(item)
      case item
      when DraftContentItem
        @live_versions[item.live_content_item.try(:id)]
      when LiveContentItem
        @live_versions[item.id]
      end
    end
  end
end
