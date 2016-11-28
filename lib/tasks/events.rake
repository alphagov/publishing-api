namespace :events do
  desc "Export events to S3. Defaults to the beginning of week 2 months ago, otherwise dates can be specified in a form that Date.parse understands."
  task :export_to_s3, [:created_before, :created_on_or_after] => :environment do |_, args|
    created_before = args[:created_before] ? Time.zone.parse(args[:created_before]) : 2.months.ago.beginning_of_week(:sunday)
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

  desc "One of task to export events before 1 month ago to S3"
  task export_all_to_s3: :environment do |_, _args|
    created_on_or_after = (Date.new(2014, 07, 01)..(Date.today - 1.month)).select(&:sunday?)

    created_on_or_after.each do |created_on_date|
      created_before = date + 7.days
      exported, s3_key = Events::S3Exporter.new(
        Time.zone.parse(created_before.to_s),
        Time.zone.parse(created_on_date.to_s)
      ).export
      puts "Exported: #{exported}, S3 key: #{s3_key}"
    end
  end
end
