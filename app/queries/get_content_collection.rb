module Queries
  class GetContentCollection
    attr_reader :content_format, :fields

    def initialize(content_format:, fields:)
      @content_format = content_format
      @fields = fields
    end

    def call
      validate_fields!

      content_items.map do |content_item|
        hash = content_item.as_json(only: fields)
        publication_state = content_item.live_content_item.present? ? 'live' : 'draft'
        hash['publication_state'] = publication_state
        hash
      end
    end

  private

    def content_items
      DraftContentItem
        .includes(:live_content_item)
        .where(format: [content_format, "placeholder_#{content_format}"])
        .select(*fields + %i[id])
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

    def permitted_fields
      DraftContentItem.column_names
    end
  end
end
