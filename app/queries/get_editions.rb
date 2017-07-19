module Queries
  class GetEditions
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

    REQUIRED_FIELDS = [
      :id,
      :document_id,
    ].freeze

    DEFAULT_FIELDS = [
      *Edition::TOP_LEVEL_FIELDS,
      :state,
      :content_id,
      :locale,
      :stale_lock_version,
      :updated_at,
      :created_at,
    ].freeze

    FIELDS_MAPPING = {
      content_id: "documents.content_id",
      locale: "documents.locale",
      stale_lock_version: "documents.stale_lock_version",
    }.freeze

    def editions
      query = Edition
        .with_document
        .where(state: filters[:states])

      query = query.where("documents.locale": filters[:locale]) if filters[:locale]
      query = query.where(publishing_app: filters[:publishing_app]) if filters[:publishing_app]

      query.select(REQUIRED_FIELDS + mapped_fields)
    end

    def mapped_fields
      fields.map do |field|
        next field unless FIELDS_MAPPING.include?(field)
        "#{FIELDS_MAPPING[field]} AS #{field}"
      end
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
      default_fields
    end

    def default_fields
      DEFAULT_FIELDS.map(&:to_s)
    end
  end
end
