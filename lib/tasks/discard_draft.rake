desc "Discard all drafts for a content item"
task :discard_draft, [:content_id] => :environment do |_, args|
  payload = { content_id: args.content_id }

  Commands::V2::DiscardDraft.call(payload)
end
