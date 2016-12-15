module Queries
  class GetLinked
    attr_reader :target_content_id, :link_type, :fields

    def initialize(content_id:, link_type:, fields:)
      self.target_content_id = content_id
      self.link_type = link_type
      self.fields = fields
    end

    def call
      validate_presence_of_item!
      validate_fields!

      content_ids = Link
        .where(target_content_id: target_content_id)
        .where(link_type: link_type)
        .joins(:link_set)
        .pluck(:content_id)

      content_items = ContentItem.where(content_id: content_ids)

      presented = presenter.present_many(content_items, fields: fields)
      presented.map { |p| filter_fields(p).as_json }
    end

  private

    attr_accessor :target_content_id, :link_type, :fields

    def validate_presence_of_item!
      return if ContentItem.exists?(
        content_id: target_content_id,
        state: %w(draft published),
      )

      raise CommandError.new(code: 404, error_details: {
        error: {
          code: 404,
          message: "No item with content_id: '#{target_content_id}'"
        }
      })
    end

    def validate_fields!
      invalid_fields = fields - permitted_fields
      return if invalid_fields.empty? && fields.any?

      if fields.empty?
        code = 422
        message = "Fields must be provided"
      else
        code = 400
        message = "Invalid column field(s): #{invalid_fields.to_sentence}"
      end

      raise CommandError.new(code: code, error_details: {
        error: {
          code: code,
          message: message
        }
      })
    end

    def filter_fields(hash)
      hash.slice(*fields)
    end

    def permitted_fields
      ContentItem.column_names + %w(base_path locale publication_state)
    end

    def presenter
      Presenters::Queries::ContentItemPresenter
    end
  end
end
