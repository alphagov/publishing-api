fields = %i{
  id
  analytics_identifier
  content_id
  description
  details
  document_type
  first_published_at
  last_edited_at
  need_ids
  phase
  public_updated_at
  publishing_app
  redirects
  rendering_app
  routes
  schema_name
  title
  update_type
  base_path
  locale
  state
  user_facing_version
}

WebContentItem = Struct.new(*fields) do
  def self.from_hash(hash)
    new(*hash.symbolize_keys.values_at(*members))
  end

  def self.from_scope(scope)
    ActiveRecord::Base.connection.exec_query(scope.to_sql).to_hash.map { |r| from_hash(r) }
  end

  def api_url
    return unless base_path
    Plek.current.website_root + "/api/content" + base_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end

  def description
    JSON.parse(self[:description])["value"]
  end
end
