namespace :content do
  desc "Resets suggested related links for the given content id(s)"
  task :reset_related_links_for_pages, [:content_ids] => :environment do |_, args|
    content_ids = args[:content_ids].split(" ")

    @failed_content_ids = []

    start_time = Time.zone.now
    puts "Start updating content items, at #{start_time}"

    content_ids.each do |content_id|
      response = Commands::V2::PatchLinkSet.call(
        content_id: content_id,
        links: {
          suggested_ordered_related_items: [],
        },
      )

      if response.code == 200
        puts "Successfully reset suggested related links for content #{content_id}"
      else
        @failed_content_ids << content_id
        warn("Failed to update content id #{content_id} - response status #{response.code}")
      end
    end

    end_time = Time.zone.now
    elapsed_time = end_time - start_time

    puts "Total elapsed time: #{elapsed_time}s"
    puts "Failed content ids: #{@failed_content_ids}"
  end
end
