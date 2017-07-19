module Queries
  class KeysetPagination::GetEditions
    attr_reader :fields, :filters

    def initialize(fields:, filters: {})
      @fields = fields || default_fields
      @filters = filters

      filters[:states] = %i(draft published unpublished) if filters[:states].blank?

      validate_fields!
    end

    def call
      editions
    end

  private

    attr_writer :fields, :filters, :pagination

    DEFAULT_FIELDS = [
      *Edition::TOP_LEVEL_FIELDS,
      :content_id,
      :locale,
      :updated_at,
      :created_at,
    ].freeze

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
