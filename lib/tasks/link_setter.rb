module Tasks
  class LinkSetter
    def self.set_primary_publishing_organisation(content_ids:, primary_publishing_organisation:, stdout: STDOUT)
      stdout.puts "Updating #{content_ids.count} documents"

      content_ids.each_with_index do |content_id, i|
        stdout.puts "#{i}: #{content_id}"

        Commands::V2::PatchLinkSet.call(
          content_id: content_id,
          links: {
            primary_publishing_organisation: [primary_publishing_organisation]
          },
          bulk_publishing: true
        )
      end
    end
  end
end
