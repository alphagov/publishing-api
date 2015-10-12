class DraftContentItem < ActiveRecord::Base
  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON

  TOP_LEVEL_FIELDS = (LiveContentItem::TOP_LEVEL_FIELDS + [
    :access_limited,
  ]).freeze

private
  def self.query_keys
    [:content_id, :locale]
  end
end
