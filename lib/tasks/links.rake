namespace :links do
  desc "Remove all links of given type to given target document"
  task :remove_from_all_documents, %w[target_content_id link_type] => :environment do |_, args|
    raise "Missing parameter: target_content_id" unless args.target_content_id

    target_content_id = args.target_content_id

    raise "Missing parameter: link_type" unless args.link_type

    link_type = args.link_type

    link_sets = LinkSet.joins(:links).where(links: { target_content_id: target_content_id, link_type: link_type })

    link_sets.each do |link_set|
      remove_link_from_link_set(args, link_set)
    rescue CommandError => e
      puts e.message
      puts "Skipping removal for document with content_id: #{link_set.content_id} ..."
      next
    end
  end

  desc "Remove link of given type to given target from given document"
  task :remove_from_document, %w[content_id target_content_id link_type] => :environment do |_, args|
    raise "Missing parameter: content_id" unless args.content_id

    content_id = args.content_id

    raise "Missing parameter: target_content_id" unless args.target_content_id

    raise "Missing parameter: link_type" unless args.link_type

    link_set = LinkSet.find_by(content_id: content_id)

    puts "Removing #{args.link_type} link to document with content_id #{args.target_content_id} from document with content_id #{content_id} ..."

    remove_link_from_link_set(args, link_set)
  end

  def remove_link_from_link_set(args, link_set)
    target_content_id = args.target_content_id
    link_type = args.link_type

    old_links = link_set.links.where(link_type: link_type)

    new_links = old_links.reject do |link|
      link.target_content_id == target_content_id && link.link_type == link_type
    end

    payload = {
      content_id: link_set.content_id,
      links: { link_type.to_sym => new_links },
      previous_version: link_set.stale_lock_version,
      bulk_publishing: true,
    }

    Commands::V2::PatchLinkSet.call(payload)
  end
end
