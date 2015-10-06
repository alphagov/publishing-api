class LinkSet < ActiveRecord::Base
  include Replaceable

private
  def self.query_keys
    ["content_id"]
  end
end
