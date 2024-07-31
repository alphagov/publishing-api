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
      embedded_editions = @edition
        .links
        .where(link_type: "embed")
        .map(&:target_documents)
        .map { |target_documents| target_documents.find_by(locale: @edition.locale) || target_documents.find_by(locale: Edition::DEFAULT_LOCALE) }
        .map(&:live)

      embedded_editions.each do |embedded_edition|
        embed_code = embedded_content_references_by_content_id[embedded_edition.content_id].embed_code
        content = content.gsub(
          embed_code,
          embedded_edition.title, # TODO: - this is not what we want (will be Government Digital Service, not 10 White Chaps)
        )
      end

      content
    end
  end
end
