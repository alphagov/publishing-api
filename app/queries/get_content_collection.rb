module Queries
  class GetContentCollection
    attr_reader(
      :document_types,
      :fields,
      :publishing_app,
      :link_filters,
      :locale,
      :pagination,
      :search_query,
      :search_in,
      :states,
    )

    def initialize(document_types:, fields:, filters: {}, pagination: Pagination.new, search_query: "", search_in: nil)
      self.document_types = Array(document_types)
      self.fields = (fields || default_fields) + ["total"]
      self.publishing_app = filters[:publishing_app]
      self.states = filters[:states]
      self.link_filters = filters[:links]
      self.locale = filters[:locale] || "en"
      self.pagination = pagination
      self.search_query = search_query.strip
      self.search_in = search_in

      validate_fields!
    end

    def call
      query.present_many
    end

    def total
      query.total
    end

  private

    attr_writer(
      :document_types,
      :fields,
      :publishing_app,
      :locale,
      :link_filters,
      :pagination,
      :search_query,
      :search_in,
      :states,
    )

    def editions
      scope = Edition.where(document_type: lookup_document_types)
      scope = scope.where(publishing_app: publishing_app) if publishing_app
      scope = scope.where(state: states) if states.present?
      scope = scope.with_document.where("documents.locale": locale) unless locale == "all"
      scope = Link.filter_editions(scope, link_filters) unless link_filters.blank?
      scope
    end

    def lookup_document_types
      document_types.flat_map { |d| [d, "placeholder_#{d}"] }
    end

    def validate_fields!
      return unless fields

      invalid_fields = fields - permitted_fields
      return unless invalid_fields.any?

      raise_error("Invalid column name(s): #{invalid_fields.to_sentence}")
    end

    def permitted_fields
      default_fields + ["total"]
    end

    def default_fields
      presenter::DEFAULT_FIELDS.map(&:to_s)
    end

    def default_search_fields
      presenter::DEFAULT_SEARCH_FIELDS
    end

    def search_fields
      return default_search_fields if search_in.blank?
      search_in.split(',').map do |field|
        elements = field.strip.split('.')
        unless permitted_fields.include?(elements.first) && elements.length <= 2
          raise_error("Invalid search field: #{field}")
        end
        if elements.length == 2
          "#{elements[0]}->>'#{escape_nested_field(elements[1])}'"
        else
          elements[0]
        end
      end
    end

    def escape_nested_field(field)
      ActiveRecord::Base.connection.quote_string(field)
    end

    def query
      @query ||= presenter.new(
        editions,
        fields: fields,
        order: pagination.order,
        offset: pagination.offset,
        locale: locale,
        limit: pagination.per_page,
        search_query: search_query,
        search_in: search_fields,
      )
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end

    def raise_error(message)
      raise CommandError.new(code: 400, error_details: {
        error: {
          code: 400,
          message: message
        }
      })
    end
  end
end
