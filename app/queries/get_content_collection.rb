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
      :states,
    )

    def initialize(document_types:, fields:, filters: {}, pagination: Pagination.new, search_query: "")
      self.document_types = Array(document_types)
      self.fields = (fields || default_fields) + ["total"]
      self.publishing_app = filters[:publishing_app]
      self.states = filters[:states]
      self.link_filters = filters[:links]
      self.locale = filters[:locale] || "en"
      self.pagination = pagination
      self.search_query = search_query.strip

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
      :states,
    )

    def editions
      scope = Edition.where(document_type: lookup_document_types)
      scope = scope.where(publishing_app: publishing_app) if publishing_app
      scope = scope.where(state: states) if states.present?
      scope = scope.joins(:document).where(documents: { locale: locale }) unless locale == "all"
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

      raise CommandError.new(code: 400, error_details: {
        error: {
          code: 400,
          message: "Invalid column name(s): #{invalid_fields.to_sentence}"
        }
      })
    end

    def permitted_fields
      default_fields + ["total"]
    end

    def default_fields
      presenter::DEFAULT_FIELDS.map(&:to_s)
    end

    def query
      @query ||= presenter.new(
        editions,
        fields: fields,
        order: pagination.order,
        offset: pagination.offset,
        locale: locale,
        limit: pagination.per_page,
        search_query: search_query
      )
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end
  end
end
