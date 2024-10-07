module Presenters
  class ContentEmbedPresenter
    def initialize(edition)
      @edition = edition
    end

    def render_embedded_content(details)
      details.each_pair do |field, value|
        next if value.blank?

        details[field] = convert_field(value)
      end

      details
    end

  private

    def embedded_editions
      @embedded_editions ||= begin
        target_content_ids = @edition
         .links
         .where(link_type: "embed")
         .pluck(:target_content_id)

        embedded_edition_ids = ::Queries::GetEditionIdsWithFallbacks.call(
          target_content_ids,
          locale_fallback_order: [@edition.locale, Edition::DEFAULT_LOCALE].uniq,
          state_fallback_order: %w[published],
        )

        Edition
        .joins("LEFT JOIN documents on documents.id = editions.document_id")
        .joins("LEFT JOIN embedded_content_references on embedded_content_references.content_id = documents.content_id")
        .where(id: embedded_edition_ids)
        .select("editions.title, editions.details, editions.document_type, embedded_content_references.friendly_id")
        .index_by(&:friendly_id)
      end
    end

    def convert_field(value)
      case value
      when Array
        value.map do |content|
          convert_field(content)
        end
      when Hash
        value.each do |nested_key, nested_value|
          value[nested_key] = convert_field(nested_value)
        end
      else
        render_embedded_editions(value)
      end
    end

    def render_embedded_editions(content)
      embedded_content_references = EmbeddedContentFinderService.new.find_content_references(content)
      return content if embedded_content_references.empty?

      embedded_content_references.each do |content_reference|
        embed_code = content_reference.embed_code
        embedded_edition = embedded_editions[content_reference.friendly_id]
        content = content.gsub(
          embed_code,
          get_content_for_edition(embedded_edition),
        )
      end

      content
    end

    # This is a temporary solution to get email address content blocks working
    # while we agree on a long-term approach that works for everything.
    def get_content_for_edition(edition)
      if edition.document_type == "content_block_email_address"
        edition.details[:email_address]
      else
        edition.title
      end
    end
  end
end
