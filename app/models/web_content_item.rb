fields = %i{
  id
  analytics_identifier
  base_path
  content_id
  description
  details
  document_type
  first_published_at
  last_edited_at
  locale
  need_ids
  phase
  public_updated_at
  publishing_app
  redirects
  rendering_app
  routes
  state
  schema_name
  title
  unpublishing_type
  update_type
  user_facing_version
}

WebContentItem = Struct.new(*fields) do
  def self.from_hash(hash)
    new(*hash.symbolize_keys.values_at(*members))
  end

  def to_h
    super.merge(
      api_path: api_path,
      api_url: api_url,
      web_url: web_url,
      withdrawn: withdrawn?,
      description: description
     )
  end

  def withdrawn?
    unpublishing_type == 'withdrawal'
  end

  def api_path
    return unless base_path
    "/api/content" + base_path
  end

  def api_url
    return unless api_path
    Plek.current.website_root + api_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end

  def description
    self[:description]["value"]
  end

  def document
    Document.find_by(content_id: content_id, locale: locale)
  end
end
