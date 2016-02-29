class CreateMissingLinkSets < ActiveRecord::Migration
  def up
    content_ids_without_link_sets = ContentItem
      .joins("LEFT JOIN link_sets on link_sets.content_id = content_items.content_id")
      .where("link_sets.id IS NULL")
      .pluck(:content_id)
      .uniq

    content_ids_without_link_sets.each do |content_id|
      puts "Creating empty LinkSet for content_id #{content_id}"
      link_set = LinkSet.create!(content_id: content_id)
      LockVersion.create!(target: link_set, number: 1)
    end

    puts "\n>>> Created #{content_ids_without_link_sets.size} link sets"
  end

  def down
  end
end
