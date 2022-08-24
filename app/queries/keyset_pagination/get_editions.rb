module Queries
  class KeysetPagination::GetEditions
    attr_reader :fields

    def initialize(params)
      @fields = params.fetch(:fields, DEFAULT_FIELDS).map(&:to_sym)
      @order = params.fetch(:order, "updated_at").to_s
      @filters = {
        states: params.fetch(:states, %i[draft published unpublished]),
        locale: params[:locale],
        publishing_app: params[:publishing_app],
        document_types: params[:document_types],
        cms_entity_ids: params.fetch(:cms_entity_ids, []),
      }

      validate_fields!
      validate_order!
    end

    def initial_query
      editions
    end

    def initial_query_fields
      fields - POST_PAGINATION_FIELDS
    end

    def post_pagination(results)
      # This could be expanded to have edition_links and linkset_links as
      # different collections
      if fields.include?(:links)
        results = add_links_to_results(results)
      end

      results
    end

    def pagination_order
      @pagination_order ||= (order.first == "-" ? :desc : :asc)
    end

    def pagination_key
      @pagination_key ||= begin
        hash = {}
        hash[pagination_field] = "editions.#{pagination_field}"
        hash[:id] = "editions.id"
        hash
      end
    end

  private

    attr_reader :order, :filters

    DEFAULT_FIELDS = [
      *Edition::TOP_LEVEL_FIELDS,
      :content_id,
      :locale,
      :updated_at,
      :created_at,
    ].freeze

    POST_PAGINATION_FIELDS = %i[links].freeze

    ORDER_FIELDS = %i[
      updated_at
      public_updated_at
      created_at
      id
    ].freeze

    def pagination_field
      @pagination_field ||= begin
        field = order.first == "-" ? order[1..order.length] : order
        field.to_sym
      end
    end

    def editions
      query = Edition
        .with_document
        .includes(:document)
        .where(state: filters[:states])

      query = query.where("documents.locale": filters[:locale]) if filters[:locale]
      query = query.where(publishing_app: filters[:publishing_app]) if filters[:publishing_app]
      query = query.where(document_type: filters[:document_types]) if filters[:document_types]
      query = query.where("cms_entity_ids @> ARRAY[?]::text[]", filters[:cms_entity_ids]) if filters[:cms_entity_ids].any?
      query
    end

    def validate_fields!
      return unless fields

      invalid_fields = fields - permitted_fields
      return unless invalid_fields.any?

      raise CommandError.new(
        code: 400,
        message: "Invalid column name(s): #{invalid_fields.to_sentence}",
      )
    end

    def validate_order!
      return if ORDER_FIELDS.include?(pagination_field)

      raise CommandError.new(
        code: 400,
        message: "Invalid order: #{pagination_field}",
      )
    end

    def permitted_fields
      DEFAULT_FIELDS + POST_PAGINATION_FIELDS
    end

    def add_links_to_results(results)
      edition_ids = results.map { |e| e[:id] }
      links = Queries::LinksForEditionIds.new(edition_ids).merged_links
      results.map { |result| result.merge(links: links[result[:id]]) }
    end
  end
end
