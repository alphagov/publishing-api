module Queries
  class GetContentCollection
    attr_reader :content_format, :fields, :locale

    def initialize(content_format:, fields:, publishing_app: nil, locale: nil)
      @content_format = content_format
      @fields = fields
      @publishing_app = publishing_app
      @locale = locale || "en"
    end

    def call
      validate_fields!
      content_items.map do |content_item|
        presenter = Presenters::Queries::ContentItemPresenter.new(
          content_item,
          draft_version(content_item),
          live_version(content_item)
        )
        select_output_fields_only(presenter)
      end
    end

  private

    attr_reader :live_versions, :draft_versions

    def content_items
      draft_items = DraftContentItem
        .includes(:live_content_item)
        .where(format: [content_format, "placeholder_#{content_format}"])
        .select(*fields + %i[id content_id])

      draft_items = draft_items.where(publishing_app: @publishing_app) if @publishing_app.present?
      draft_items = draft_items.where(locale: locale) unless locale == 'all'

      live_items = LiveContentItem
        .where("draft_content_item_id IS NULL")
        .where(format: [content_format, "placeholder_#{content_format}"])
        .select(*fields + %i[id])

      live_items = live_items.where(publishing_app: @publishing_app) if @publishing_app.present?
      live_items = live_items.where(locale: locale) unless locale == 'all'

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

    def select_output_fields_only(presenter)
      presenter.present.slice(*output_fields).as_json
    end
  end
end
