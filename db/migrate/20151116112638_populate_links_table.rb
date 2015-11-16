class PopulateLinksTable < ActiveRecord::Migration
  def change
    puts "Populating Links table"
    LinkSet.find_each do |link_set|
      link_set.links.each do |link_type, target_content_ids|
        target_content_ids.each do |target_content_id|
          Link.new(
            link_set: link_set,
            link_type: link_type,
            target_content_id: target_content_id,
          )
          print "."
        end
      end
    end
    puts "\nDone."
  end
end
