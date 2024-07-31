class ContentEmbedService
  include ApplicationHelper

  SUPPORTED_DOCUMENT_TYPES = %w[contact email_address].freeze
  UUID_REGEX = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
  EMBED_REGEX = /({{embed:(#{SUPPORTED_DOCUMENT_TYPES.join('|')}):#{UUID_REGEX}}})/

  class EmbeddedEdition
    attr_reader :embed_code, :document_type, :content_id

    def initialize(embed_code:, document_type:, content_id:)
      @embed_code = embed_code
      @document_type = document_type
      @content_id = content_id
    end

    def edition
      @edition ||= Edition.with_document.find_by(
        state: "published",
        content_store: "live",
        document_type: @document_type,
        documents: { content_id: @content_id },
      )
    end
  end

  def initialize(body)
    @body = body
  end

  def embedded_editions
    @embedded_editions ||= @body.scan(EMBED_REGEX).map do |match|
      EmbeddedEdition.new(
        embed_code: match[0],
        document_type: match[1],
        content_id: match[2],
      )
    end
  end

  def fetch_links
    embedded_editions.group_by(&:document_type).transform_values do |items|
      items.map(&:content_id)
    end
  end

  def render
    embedded_editions.each do |embedded_edition|
      replace_embed_code_with_content(embedded_edition.embed_code, embedded_edition.edition)
    end

    @body
  end

private

  def find_edition(document_type, content_id)
    Edition.with_document.find_by(
      state: "published",
      content_store: "live",
      document_type:,
      documents: { content_id: },
    )
    ## TODO: What do we do if the edition can't be found?
  end

  def replace_embed_code_with_content(embed_code, edition)
    @body.gsub!(
      embed_code,
      renderer.render(partial: view_for_document_type(edition.document_type), locals: { details: edition.details }, formats: [:html]),
    )
  end

  def renderer
    @renderer ||= ActionController::Base
  end

  def view_for_document_type(document_type)
    {
      "contact" => "contacts/contact",
    }[document_type]
  end
end
