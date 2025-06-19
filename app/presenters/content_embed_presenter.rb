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
      @embedded_editions ||=
        ::Queries::GetEmbeddedEditionsFromHostEdition.call(edition: @edition)
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
      when String
        render_embedded_editions(value)
      else
        value
      end
    end

    def render_embedded_editions(content)
      embedded_content_references = EmbeddedContentFinderService.new.find_content_references(content)

      return content if embedded_content_references.empty?

      processed_content = content.dup
      embedded_content_references.uniq.each do |content_reference|
        embed_code = content_reference.embed_code
        embedded_edition = embedded_editions[content_reference.identifier]

        if embedded_edition.present?
          rendered_content = get_content_for_edition(embedded_edition, embed_code)
          processed_content = processed_content.gsub(
            /(?<!data-embed-code=")#{Regexp.escape(embed_code)}(?!")/,
            rendered_content,
          )
        else
          GovukError.notify(CommandError.new(
                              code: 422,
                              message: "Could not find a live edition for embedded content ID: #{content_reference.identifier}",
                            ))
        end
      end

      processed_content
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
