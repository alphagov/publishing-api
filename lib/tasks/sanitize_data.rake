desc "Sanitize access limited data"
task sanitize_data: :environment do
  Tasks::DataSanitizer.delete_access_limited(STDOUT)
end

namespace :db do
  desc "Resolves invalid versions detected by validate:versions task"
  task resolve_invalid_versions: :environment do
    Tasks::VersionResolver.resolve
  end
end

task :restore_policy_links, [:action] => [:environment] do |_, args|
  dry_run = args["action"] != 'apply'
  puts "Dry run" if dry_run

  policy_query = Queries::GetContentCollection.new(
    document_type: 'policy',
    fields: %w(content_id),
    pagination: NullPagination.new
  )
  policy_content_ids = policy_query.call.map { |item| item["content_id"] }

  # Identify the destructive events
  policy_wipe_events = Event
    .where("created_at::date = '2016-03-14' and action = 'PatchLinkSet'")
    .where(content_id: policy_content_ids)
    .order("content_id, created_at asc")

  wipe_events_by_content_id = Hash.new { |h, k| h[k] = [] }

  puts "Found #{policy_wipe_events.size} destructive events"

  policy_wipe_events.each do |event|
    puts "#{event.content_id} #{event.action} #{event.created_at} #{event.payload[:links]}"

    wipe_events_by_content_id[event.content_id] << event.id
  end

  puts

  # Restore the links
  policy_wipe_events.each do |wipe_event|
    puts "Restoring #{wipe_event.content_id}..."

    policy_events = Event.where(
      content_id: wipe_event.content_id,
      action: %w(PutContentWithLinks PatchLinkSet)
    ).order("created_at desc")

    policy_log = []

    policy_events.each do |event|
      policy_log << event
      break if event.action == 'PutContentWithLinks'
    end

    raise "Event log error: no events found for #{wipe_event.content_id}" if policy_log.empty?

    if policy_log.last.action != 'PutContentWithLinks'
      # Policy created since Publishing API V2
      puts "New policy #{wipe_event.content_id}"
    end

    policy_log.reverse_each do |event|
      unless wipe_events_by_content_id[event.content_id].include?(event.id)
        puts "Reapplying #{event.created_at} #{event.action}: #{event.payload[:links]}"
        Commands::V2::PatchLinkSet.call(event.payload) unless dry_run
      end
    end

    puts
  end
end
