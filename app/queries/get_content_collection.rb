module Queries
  class GetContentCollection
    attr_reader(
      :fields,
      :publishing_app,
      :link_filters,
      :locale,
      :pagination,
      :search_query,
      :search_in,
      :states,
    )

    def initialize(fields:, document_types: @document_types, filters: {}, pagination: Pagination.new, search_query: "", search_in: nil)
      self.document_types = Array(document_types)
      self.fields = (fields || default_fields) + %w[total]
      self.publishing_app = filters[:publishing_app]
      self.states = filters[:states] || %i[draft published unpublished]
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

    delegate :total, to: :query

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
      scope = Edition.with_document
      scope = scope.where(document_type: @document_types) if @document_types.any?
      scope = scope.where(publishing_app:) if publishing_app
      scope = scope.where("documents.locale": locale) unless locale == "all"
      scope = Link.filter_editions(scope, link_filters) if link_filters.present?
      scope
    end

    def validate_fields!
      return unless fields

      invalid_fields = fields - permitted_fields
      return unless invalid_fields.any?

      raise_error("Invalid column name(s): #{invalid_fields.to_sentence}")
    end

    def permitted_fields
      default_fields + %w[total]
    end

    def default_fields
      presenter::DEFAULT_FIELDS.map(&:to_s)
    end

    def default_search_fields
      presenter::DEFAULT_SEARCH_FIELDS
    end

    def allowed_search_fields
      presenter::SEARCH_FIELDS
    end

    def allowed_nested_search_fields
      presenter::NESTED_SEARCH_FIELDS
    end

    def search_fields
      return default_search_fields if search_in.blank?

      search_in.map { |field| search_field_for_query(field) }
    end

    def search_field_for_query(field)
      raise_error("Invalid search field: #{field}") unless valid_search_field?(field)
      return field unless field.include?(".")

      elements = field.split(".")
      "#{elements[0]}->>'#{escape_nested_field(elements[1])}'"
    end

    def valid_search_field?(field)
      return true if allowed_search_fields.include?(field)

      elements = field.split(".")
      allowed_nested_search_fields.include?(elements[0]) && elements.length == 2
    end

    def escape_nested_field(field)
      ActiveRecord::Base.connection.quote_string(field)
    end

    def query
      @query ||= presenter.new(
        editions,
        fields:,
        order: pagination.order,
        offset: pagination.offset,
        locale:,
        limit: pagination.per_page,
        search_query:,
        search_in: search_fields,
        states:,
      )
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end

    def raise_error(message)
      raise CommandError.new(
        code: 400,
        error_details: {
          error: {
            code: 400,
            message:,
          },
        },
      )
    end
  end
end
