class LinkSet < ActiveRecord::Base
  has_many :links

  include Replaceable

  def hashed_links
    links = Link.where(link_set: self)

    links_hash = Hash.new

    links.each do |l|
      if links_hash.has_key?(l.link_type)
        links_hash[l.link_type] << l.target_content_id
      else
        links_hash[l.link_type] = [l.target_content_id]
      end
    end

    links_hash.symbolize_keys
  end

private
  def self.query_keys
    [:content_id]
  end
end
