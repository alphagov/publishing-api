class DataSanitizer
  def self.delete_access_limited(stdout)
    AccessLimit.all.find_each do |access_limit|
      limited_draft = access_limit.edition
      stdout.puts "Discarding access limited draft edition '#{limited_draft.content_id}'"
      simulated_payload = limited_draft.to_h
      Commands::V2::DiscardDraft.call(simulated_payload, downstream: true)
    end
  end
end
