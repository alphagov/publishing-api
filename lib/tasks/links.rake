namespace :links do
  desc "Remove all links of given type to given target document"
  task remove_related_links_to_business_finder: :environment do
    BUSINESS_FINDER_CONTENT_ID = "42ce66de-04f3-4192-bf31-8394538e0734".freeze
    LINK_TYPE = "ordered_related_items".freeze

    link_sets = LinkSet.joins(:links).where(links: { target_content_id: BUSINESS_FINDER_CONTENT_ID, link_type: LINK_TYPE })

    link_sets.each do |link_set|
      remove_link_from_link_set(
        target_content_id: BUSINESS_FINDER_CONTENT_ID,
        link_type: LINK_TYPE,
        link_set: link_set,
      )
    rescue CommandError => e
      puts e.message
      puts "Skipping removal for document with content_id: #{link_set.content_id} ..."
      next
    end
  end

  def remove_link_from_link_set(target_content_id:, link_type:, link_set:)
    old_links = link_set.links.where(link_type: link_type)

    puts "OLD LINKS:"
    puts old_links.pluck(:target_content_id).inspect

    puts "NEW LINKS:"
    puts new_links_target_content_ids(target_content_id, link_type, link_set).inspect

    payload = {
      content_id: link_set.content_id,
      links: {
        link_type.to_sym => new_links_target_content_ids(target_content_id, link_type, link_set),
      },
      previous_version: link_set.stale_lock_version,
      bulk_publishing: true,
    }

    puts "PAYLOAD:"
    puts payload.inspect

    Commands::V2::PatchLinkSet.call(payload)
  end

  def new_links_target_content_ids(target_content_id, link_type, link_set)
    link_set.links
      .where(link_type: link_type)
      .where.not(target_content_id: target_content_id)
      .pluck(:target_content_id)
  end
end
