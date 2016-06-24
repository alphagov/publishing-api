require "forwardable"

class WebContentItem
  extend Forwardable

  attr_reader :content_item, :base_path, :locale

  def initialize(content_item, base_path: nil, locale: nil)
    @content_item = content_item
    @base_path = base_path || Location.find_by(content_item: content_item).try(:base_path)
    @locale = locale || Translation.find_by(content_item: content_item).try(:locale)
  end

  CONTENT_ITEM_METHODS = [
    :analytics_identifier,
    :content_id,
    :description,
    :details,
    :public_updated_at,
    :schema_name,
    :title,
  ]

  def_delegators :@content_item, *CONTENT_ITEM_METHODS

  def api_url
    return unless base_path
    Plek.current.website_root + "/api/content" + base_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end
end
