class LinkSet < ActiveRecord::Base
  has_many :links, dependent: :destroy

  include Replaceable

  def self.query_keys
    [:content_id]
  end
end
