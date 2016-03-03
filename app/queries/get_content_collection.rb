module Queries
  class GetContentCollection
    attr_reader :content_format, :fields, :publishing_app, :locale, :pagination

    def initialize(content_format:, fields:, publishing_app: nil, locale: nil, pagination: Pagination.new)
      self.content_format = content_format
      self.pagination = pagination
      self.fields = fields_with_ordering(fields)
      self.publishing_app = publishing_app
      self.locale = locale || "en"
    end

    def call
      validate_fields!

      content_items = ContentItem.where(format: lookup_formats)

      if publishing_app
        content_items = content_items.where(publishing_app: publishing_app)
      end

      if locale && locale != "all"
        content_items = Translation.filter(content_items, locale: locale)
      end

      content_items = pagination.paginate(content_items)
      presented = presenter.present_many(content_items, fields: fields, order: pagination.order)

      presented.map { |p| filter_fields(p).as_json }
    end

  private

    attr_writer :content_format, :fields, :publishing_app, :locale, :pagination

    def lookup_formats
      [content_format, "placeholder_#{content_format}"]
    end

    def filter_fields(hash)
      hash.slice(*fields)
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

    def fields_with_ordering(fields)
      combined_fields = pagination.order_fields
      combined_fields = combined_fields + fields if fields
      combined_fields
    end

    def permitted_fields
      ContentItem.column_names + %w(base_path locale publication_state internal_name)
    end

    def select_output_fields_only(presenter)
      presenter.present.slice(*fields).as_json
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end
  end
end
