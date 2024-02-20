desc "Remove draft specialist finder docs by type"
task :remove_draft_specialist_finder_docs, [:document_type] => :environment do |_, args|
  # document_type example: "farming_grant_option"
  raise "Missing parameter: document_type" unless args.document_type

  results = Queries::GetContentCollection.new(fields: %w[content_id], document_types: args.document_type).call
  results.map do |payload|
    Commands::V2::DiscardDraft.call(payload.deep_symbolize_keys)
  rescue StandardError => e
    Sidekiq.logger.info(e)
  end
end
