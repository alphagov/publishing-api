namespace :events do
  desc "Export events to S3. Defaults to the beginning of week 2 months ago, otherwise dates can be specified in a form that Date.parse understands."
  task :export_to_s3, [:created_before, :created_on_or_after] => :environment do |_, args|
    created_before = args[:created_before] ? Time.zone.parse(args[:created_before]) : 1.months.ago.beginning_of_week(:sunday)
    created_on_or_after = args[:created_on_or_after] ? Time.zone.parse(args[:created_on_or_after]) : nil
    exported, s3_key = Events::S3Exporter.new(created_before, created_on_or_after).export
    puts "Exported #{exported} event#{exported == 1 ? '' : 's'} successfully to #{s3_key} 🎉"
  end

  # To access a particular bucket or use different credentials you can pass in enviornment variables e.g.
  # $ EVENT_LOG_AWS_ACCESS_ID=AKIAIOSFODNN7EXAMPLE EVENT_LOG_AWS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY EVENT_LOG_AWS_BUCKETNAME=govuk-publishing-api-event-log-integration S3_EXPORT_REGION=eu-west-1 rake 'events:import_from_s3[events/2015-12-12T00:00:00+00:00.csv.gz]'
  desc "Import events from S3. The S3 key to the file is provided as an argument. You can provide environment variables to access a particular S3 bucket"
  task :import_from_s3, [:s3_key] => :environment do |_, args|
    imported = Events::S3Importer.new(args[:s3_key]).import
    puts "Imported #{imported} event#{imported == 1 ? '' : 's'} successfully 🍾"
  end

  # $ EVENT_LOG_AWS_ACCESS_ID=AKIAIOSFODNN7EXAMPLE EVENT_LOG_AWS_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY EVENT_LOG_AWS_BUCKETNAME=govuk-publishing-api-event-log-integration S3_EXPORT_REGION=eu-west-1 rake 'events:import_content_id_events[content_id]'
  desc "import all events matching a content_id"
  task :import_content_id_events, [:content_id] => :environment do |_, args|
    event_dates = Event.where(content_id: args[:content_id]).where("payload IS NULL").pluck(:created_at)
    importer = Events::S3Importer.new
    s3_keys = event_dates.map do |event_date|
      start_event = event_date - event_date.wday
      "events/#{Time.zone.parse(start_event.to_s).strftime('%FT%T%:z')}.csv.gz"
    end
    s3_keys.uniq.each do |key|
      begin
        imported = importer.import(key)
        puts "Imported #{imported} successfully"
      rescue Events::S3Importer::BucketNotConfiguredError => e
        puts "skipped #{key} #{e}"
      end
    end
  end
end
