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
  api_path
  api_url
  web_url
  withdrawn
}

WebContentItem = Struct.new(*fields) do
  def self.from_hash(hash)
    new(*hash.symbolize_keys.values_at(*members))
  end

  def to_h
    h = super

    h[:first_published_at] = first_published_at.iso8601 if first_published_at
    h[:last_edited_at] = last_edited_at.iso8601 if last_edited_at
    h[:public_updated_at] = public_updated_at.iso8601 if public_updated_at

    h
  end

  def document
    Document.find_by(content_id: content_id, locale: locale)
  end
end
