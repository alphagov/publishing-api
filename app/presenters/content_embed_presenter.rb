module Presenters
  class ContentEmbedPresenter
    def initialize(edition)
      @edition = edition
    end

    def render_embedded_content(details)
      return details unless target_content_ids

      details.each_pair do |field, value|
        next if value.blank?

        details[field] = convert_field(value)
      end

      details
    end

  private

    def target_content_ids
      @target_content_ids ||= @edition
                                .links
                                .where(link_type: "embed")
                                .pluck(:target_content_id)
    end

    def embedded_editions
      @embedded_editions ||= begin
        embedded_edition_ids = ::Queries::GetEditionIdsWithFallbacks.call(
          target_content_ids,
          locale_fallback_order: [@edition.locale, Edition::DEFAULT_LOCALE].uniq,
          state_fallback_order: %w[published],
        )

        Edition.where(id: embedded_edition_ids).index_by(&:content_id)
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

      embedded_content_references.uniq.each do |content_reference|
        embed_code = content_reference.embed_code
        embedded_edition = embedded_editions[content_reference.content_id]
        if embedded_edition.present?
          content = content.gsub(
            embed_code,
            get_content_for_edition(embedded_edition, embed_code),
          )
        else
          Sentry.capture_exception(CommandError.new(
                                     code: 422,
                                     message: "Could not find a live edition for embedded content ID: #{content_reference.content_id}",
                                   ))
        end
      end

      content
    end

    def get_content_for_edition(edition, embed_code)
      ContentBlockTools::ContentBlock.new(
        document_type: edition.document_type,
        content_id: edition.document.content_id,
        title: edition.title,
        details: edition.details,
        embed_code: embed_code,
      ).render
    end
  end
end
