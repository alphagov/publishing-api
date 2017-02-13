class ContentItem
  attr_reader :edition

  def initialize(edition)
    @edition = edition
  end

  def present
    SymbolizeJSON.symbolize(
      edition.attributes.merge(
        api_path: api_path,
        api_url: api_url,
        web_url: web_url,
        withdrawn: withdrawn?,
        content_id: content_id,
        locale: locale,
      )
    )
  end

  def document_type
    edition.document_type
  end

  def content_id
    edition.document.content_id
  end

private

  def locale
    edition.document.locale
  end

  def withdrawn?
    edition.unpublishing.present? && edition.unpublishing.withdrawal?
  end

  def api_path
    return unless edition.base_path
    "/api/content" + edition.base_path
  end

  def api_url
    return unless edition.api_path
    Plek.current.website_root + edition.api_path
  end

  def web_url
    return unless edition.base_path
    Plek.current.website_root + edition.base_path
  end

end
