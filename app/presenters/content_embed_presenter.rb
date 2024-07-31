module Presenters
  class ContentEmbedPresenter
    def initialize(edition)
      @edition = edition
    end

    def render_embedded_content(details)
      return details if details[:body].nil?

      details[:body] = if details[:body].is_a?(Array)
                         details[:body].map do |content|
                           {
                             content_type: content[:content_type],
                             content: render_embedded_editions(content[:content]),
                           }
                         end
                       else
                         render_embedded_editions(details[:body])
                       end

      details
    end

  private

    def render_embedded_editions(content)
      embedded_content_references = EmbeddedContentFinderService.new.find_content_references(content)
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
          embedded_edition.title,
        )
      end

      content
    end
  end
end
