class ContentEmbedService
  include ApplicationHelper

  SUPPORTED_DOCUMENT_TYPES = %w[contact].freeze
  UUID_REGEX = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
  EMBED_REGEX = /({{embed:(#{SUPPORTED_DOCUMENT_TYPES.join('|')}):#{UUID_REGEX}}})/

  def initialize(body)
    @body = body
  end

  def render
    match_data = @body.scan(EMBED_REGEX)

    match_data.each do |match|
      embed_code = match[0]
      document_type = match[1]
      content_id = match[2]

      edition = find_edition(document_type, content_id)
      # TODO: Link Edition to document
      replace_embed_code_with_content(embed_code, edition)
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
