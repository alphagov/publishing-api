desc "Discard all drafts for a content item"
task :discard_draft, [:content_id] => :environment do |_, args|
  raise 'Missing parameter: content_id' unless args.content_id

  payload = { content_id: args.content_id }

  Commands::V2::DiscardDraft.call(payload)
end
