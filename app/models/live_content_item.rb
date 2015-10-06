class LiveContentItem < ActiveRecord::Base
  include Replaceable

private
  def self.query_keys
    ["content_id", "locale"]
  end
end
