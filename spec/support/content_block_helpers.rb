module ContentBlockHelpers
  def presented_details_for(edition, embed_code)
    ContentBlockTools::ContentBlock.new(
      document_type: edition.document_type,
      content_id: edition.document.content_id,
      title: edition.title,
      details: edition.details,
      embed_code: embed_code,
    ).render
  end
end

RSpec.configure do |c|
  c.include ContentBlockHelpers
end
