module Queries
  class KeysetPagination::GetEditions
    attr_reader :fields

    def initialize(params)
      @fields = params[:fields] || default_fields
      @order = params[:order] || "updated_at"
      @filters = {
        states: params[:states] || %i(draft published unpublished),
        locale: params[:locale],
        publishing_app: params[:publishing_app],
      }

      validate_fields!
    end

    def call
      editions
    end

    def pagination_order
      @pagination_order ||= (order.first == "-" ? :desc : :asc)
    end

    def pagination_key
      @pagination_key ||= (
        hash = {}
        hash[pagination_field] = "editions.#{pagination_field}"
        hash[:id] = "editions.id"
        hash
      )
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

    def pagination_field
      @pagination_field ||= (if order.first == "-"
                               order[1..order.length]
                             else
                               order
                             end).to_sym
    end

    def editions
      query = Edition
        .with_document
        .includes(:document)
        .where(state: filters[:states])

      query = query.where("documents.locale": filters[:locale]) if filters[:locale]
      query = query.where(publishing_app: filters[:publishing_app]) if filters[:publishing_app]

      query
    end

    def validate_fields!
      return unless fields

      invalid_fields = fields - permitted_fields
      return unless invalid_fields.any?

      raise CommandError.new(
        code: 400,
        message: "Invalid column name(s): #{invalid_fields.to_sentence}"
      )
    end

    def permitted_fields
      default_fields
    end

    def default_fields
      DEFAULT_FIELDS.map(&:to_s)
    end
  end
end
