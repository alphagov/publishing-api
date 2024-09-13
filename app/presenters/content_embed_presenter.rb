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

      embedded_content_references_by_content_id = embedded_content_references.index_by(&:content_id)

      target_content_ids = @edition
        .links
        .where(link_type: "embed")
        .pluck(:target_content_id)

      embedded_edition_ids = ::Queries::GetEditionIdsWithFallbacks.call(
        target_content_ids,
        locale_fallback_order: [@edition.locale, Edition::DEFAULT_LOCALE].uniq,
        state_fallback_order: %w[published],
      )

      embedded_editions = Edition.where(id: embedded_edition_ids)

      embedded_editions.each do |embedded_edition|
        embed_code = embedded_content_references_by_content_id[embedded_edition.content_id].embed_code
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
