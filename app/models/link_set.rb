class LinkSet < ActiveRecord::Base
  # This has been introduced for avoiding clashes with the `Link` column.
  # Remove this line when dropping the column.
  has_many :content_item_links, :class_name => 'Link', dependent: :destroy

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
