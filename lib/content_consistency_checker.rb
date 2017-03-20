require 'gds_api/content_store'

class ContentConsistencyChecker
  attr_reader :errors

  def initialize(content_id, locale = "en", ignore_recent = false)
    @content_id = content_id
    @locale = locale
    @ignore_recent = ignore_recent
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

  attr_reader :content_id, :locale, :ignore_recent

  def check_edition(prefix, edition, content_store)
    return unless edition.base_path

    return if ignore_recent && edition.updated_at < 1.day.ago

    path = edition.base_path

    begin
      content_item = content_store.content_item(path).parsed_content
    rescue GdsApi::HTTPForbidden
      # nothing
    rescue GdsApi::ContentStore::ItemNotFound
      errors << "#{prefix} #{path} content is missing from the content store."
    rescue GdsApi::HTTPGone
      if edition.gone?
        return
      else
        errors << "#{prefix} #{path} is gone in the content store."
      end
    end

    return if content_item.nil?

    if edition.redirect?
      if content_item["document_type"] != "redirect" ||
          content_item["schema_name"] != "redirect"
        errors << "#{prefix} content is not a redirect in the content store."
      end
    elsif edition.gone?
      if content_item["document_type"] != "gone" ||
          content_item["schema_name"] != "gone"
        errors << "#{prefix} content is not gone in the content store."
      end
    else
      fields = [:rendering_app, :publishing_app, :schema_name, :document_type]
      fields.each do |field|
        edition_value = edition.send(field)
        content_item_value = content_item[field.to_s]

        if edition_value != content_item_value
          errors << "#{prefix} edition #{field} (#{edition_value}) does not match content store (#{content_item_value})."
        end
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
