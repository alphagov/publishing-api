class PopulateLinks < ActiveRecord::Migration
  def up
    link_sets_with_populated_links = LinkSet.includes(:links).where("legacy_links::text <> '{}'::text")
    link_sets_with_populated_links.find_each do |link_set|
      # Only copy the links for items that haven't been touched since deploy.
      next unless link_set.links.size == 0

      link_set.legacy_links.each do |link_type, content_ids|
        content_ids.each do |content_id|
          link_set.links.create! link_type: link_type, target_content_id: content_id
        end
      end
    end
  end
end
