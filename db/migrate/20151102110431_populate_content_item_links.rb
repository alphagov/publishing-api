class PopulateContentItemLinks < ActiveRecord::Migration
  def change
    LinkSet.all.each do |link_set|
      puts "Adding linked items for #{link_set.content_id}"
      ContentItemLinkPopulator.create_or_replace(link_set.content_id, link_set.links)
    end
  end
end
