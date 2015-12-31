module Tasks
  class DataSanitizer
    def self.delete_access_limited(stdout)
      AccessLimit.all.each do |access_limit|
        limited_draft = access_limit.target
        stdout.puts "Discarding access limited draft content item '#{limited_draft.content_id}'"
        simulated_payload = limited_draft.as_json.symbolize_keys
        Commands::V2::DiscardDraft.call(simulated_payload, downstream: true)
      end
    end
  end
end
