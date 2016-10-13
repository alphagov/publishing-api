module Queries
  class GetContentCollection
    attr_reader :document_types, :fields, :publishing_app, :link_filters, :locale, :pagination, :search_query

    def initialize(document_types:, fields:, filters: {}, pagination: Pagination.new, search_query: "")
      self.document_types = Array(document_types)
      self.fields = fields
      self.publishing_app = filters[:publishing_app]
      self.link_filters = filters[:links]
      self.locale = filters[:locale] || "en"
      self.pagination = pagination
      self.search_query = search_query.strip
    end

    def call
      validate_fields!

      presenter.present_many(
        content_items,
        fields: fields,
        order: pagination.order,
        offset: pagination.offset,
        locale: locale,
        limit: pagination.per_page,
        search_query: search_query
      )
    end

    def total
      @total ||= presenter.new(content_items,
                               locale: locale,
                               search_query: search_query).total
    end

  private

    attr_writer :document_types, :fields, :publishing_app, :locale, :link_filters, :pagination, :search_query

    def content_items
      scope = ContentItem.where(document_type: lookup_document_types)
      scope = scope.where(publishing_app: publishing_app) if publishing_app
      scope = Link.filter_content_items(scope, link_filters) unless link_filters.blank?
      scope = Translation.filter(scope, locale: locale) unless locale == "all"
      scope
    end


    def lookup_document_types
      document_types.flat_map { |d| [d, "placeholder_#{d}"] }
    end

    def validate_fields!
      return unless fields

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
      presenter::DEFAULT_FIELDS.map(&:to_s)
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end
  end
end
