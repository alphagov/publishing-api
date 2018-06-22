desc "Publish the draft of a a content item"
task :publish, %i(content_id locale) => :environment do |_, args|
  payload = {
    content_id: args.fetch(:content_id),
    locale: args.fetch(:locale, "en")
  }

  begin
    Commands::V2::Publish.call(payload)

    puts ""
    puts "Published #{payload[:content_id]} / #{payload[:locale]}"
  rescue CommandError => e
    puts "Error: #{e.message}"
    pp e.error_details
    exit 1
  end
end
