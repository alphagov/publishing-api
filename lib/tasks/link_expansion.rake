namespace :link_expansion do
  desc "Expand links from a content ID using the new 'fast' link expansion code"
  task :fast_by_content_id, [:content_id] => :environment do |_, args|
    result = FastLinkExpansion.by_content_id(args.fetch(:content_id)).links_with_content
    puts result.to_json
  end

  desc "Expand links from a content ID using the old 'slow' link expansion code"
  task :by_content_id, [:content_id] => :environment do |_, args|
    result = LinkExpansion.by_content_id(args.fetch(:content_id)).links_with_content
    puts result.to_json
  end
end
