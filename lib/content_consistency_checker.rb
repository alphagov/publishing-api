require 'gds_api/content_store'

class ContentConsistencyChecker
  attr_reader :errors

  def initialize(content_id, locale = "en")
    @content_id = content_id
    @locale = locale
    @errors = []
  end

  def call
    unless document
      errors << "Document (#{content_id}, #{locale}) could not be found."
      return errors
    end

    check_edition("Draft", draft, draft_content_store) if draft
    check_edition("Live", live, live_content_store) if live

    errors
  end

private

  attr_reader :content_id, :locale

  def item_from_content_store(path, content_store)
    begin
      content_store.content_item(path).parsed_content
    rescue GdsApi::ContentStore::ItemNotFound, GdsApi::HTTPGone, GdsApi::HTTPForbidden
      nil
    end
  end

  def check_edition(prefix, edition, content_store)
    return unless edition.base_path

    content_item = item_from_content_store(edition.base_path, content_store)

    if edition.gone? && content_item
      errors << "#{prefix} content exists in the content store."
    elsif content_item.nil?
      errors << "#{prefix} content is missing from the content store."
      return
    end

    fields = [:rendering_app, :publishing_app, :schema_name, :document_type]
    fields.each do |field|
      edition_value = edition.send(field)
      content_item_value = content_item[field.to_s]

      if edition_value != content_item_value
        errors << "#{prefix} edition #{field} (#{edition_value}) does not match content store (#{content_item_value})."
      end
    end
  end

  def live
    document.live
  end

  def draft
    document.draft
  end

  def document
    @document ||= Document.find_by(content_id: content_id, locale: locale)
  end

  def live_content_store
    GdsApi::ContentStore.new(Plek.find("content-store"))
  end

  def draft_content_store
    GdsApi::ContentStore.new(Plek.find("draft-content-store"))
  end
end
