desc "Remove suggested_ordered_related_items from all content"
task remove_suggested_related_links: :environment do
  # Find all the editions with suggested links
  puts "Fetching content IDs with suggested links..."

  content_ids = Link.where(link_type: "suggested_ordered_related_items")
                    .joins(:link_set)
                    .pluck("link_sets.content_id")
                    .uniq

  puts "Found #{content_ids.count} items to update."

  successful_count = 0
  failed_content_ids = []

  # Patch the editions to remove the suggested related links
  content_ids.each_with_index do |content_id, _index|
    Commands::V2::PatchLinkSet.call(
      { content_id: content_id,
        links: {
          suggested_ordered_related_items: [],
        } },
    )

    successful_count += 1
  rescue StandardError => e
    failed_content_ids << content_id
    warn "\nFailed to update #{content_id}: #{e.message}"
  end

  puts "\n--- Job Complete ---"
  puts "Successfully updated: #{successful_count}"
  puts "Failed: #{failed_content_ids.count}"

  if failed_content_ids.any?
    puts "Failed IDs: #{failed_content_ids.join(', ')}"
  end
end
