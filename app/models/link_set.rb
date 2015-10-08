class LinkSet < ActiveRecord::Base
  include Replaceable
  include SymbolizeJSON

private
  def self.query_keys
    [:content_id]
  end
end
