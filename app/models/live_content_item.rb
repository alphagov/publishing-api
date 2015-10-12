class LiveContentItem < ActiveRecord::Base
  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON

  TOP_LEVEL_FIELDS = [
    :base_path,
    :content_id,
    :description,
    :details,
    :format,
    :locale,
    :public_updated_at,
    :publishing_app,
    :redirects,
    :rendering_app,
    :routes,
    :title,
  ].freeze

private
  def self.query_keys
    [:content_id, :locale]
  end
end
