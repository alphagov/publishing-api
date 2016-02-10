module Queries
  class GetContentCollection
    attr_reader :content_format, :fields, :publishing_app

    def initialize(content_format:, fields:, publishing_app: nil)
      self.content_format = content_format
      self.fields = fields
      self.publishing_app = publishing_app
    end

    def call
      validate_fields!

      content_items = ContentItem.where(format: lookup_formats)

      if publishing_app
        content_items = content_items.where(publishing_app: publishing_app)
      end

      content_items.map do |item|
        presented = Presenters::Queries::ContentItemPresenter.present(item)
        filter_fields(presented).as_json
      end
    end

  private
    attr_writer :content_format, :fields, :publishing_app

    def lookup_formats
      [content_format, "placeholder_#{content_format}"]
    end

    def output_fields
      fields.map(&:to_sym) + [:publication_state]
    end

    def filter_fields(hash)
      hash.slice(*output_fields)
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
      ContentItem.column_names + %w(base_path locale)
    end
  end
end
