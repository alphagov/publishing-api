require "forwardable"

class WebContentItem
  NullLocation = Struct.new(:base_path)
  NullTranslation = Struct.new(:locale)

  attr_reader :content_item, :location, :translation
  extend Forwardable

  def initialize(content_item)
    @content_item = content_item
    @location = Location.find_by(content_item: content_item) || NullLocation.new
    @translation = Translation.find_by(content_item: content_item) || NullTranslation.new
  end

  CONTENT_ITEM_METHODS = [
    :content_id, :description, :analytics_identifier, :title
  ]

  def_delegators :@content_item, *CONTENT_ITEM_METHODS
  def_delegators :@location, :base_path
  def_delegators :@translation, :locale

  def api_url
    return unless base_path
    Plek.current.website_root + "/api/content" + base_path
  end

  def web_url
    return unless base_path
    Plek.current.website_root + base_path
  end
end
