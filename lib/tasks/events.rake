namespace :events do
  desc "Export events to S3. Defaults to the beginning of week 2 months ago, otherwise dates can be specified in a form that Date.parse understands."
  task :export_to_s3, [:created_before, :created_on_or_after] => :environment do |_, args|
    created_before = args[:created_before] ? Time.zone.parse(args[:created_before]) : 1.months.ago.beginning_of_week(:sunday)
    created_on_or_after = args[:created_on_or_after] ? Time.zone.parse(args[:created_on_or_after]) : nil
    exported, s3_key = Events::S3Exporter.new(created_before, created_on_or_after).export
    puts "Exported #{exported} event#{exported == 1 ? '' : 's'} successfully to #{s3_key} 🎉"
  end

  desc "Import events from S3. The S3 key to the file is provided as an argument. See docs/restoring-events.md."
  task :import_from_s3, [:s3_key] => :environment do |_, args|
    imported = Events::S3Importer.new.import_from_s3_by_key(args[:s3_key])
    puts "Imported #{imported} event#{imported == 1 ? '' : 's'} successfully 🍾"
  end

  desc "Download all archive files to `tmp/events`. Use this to do a local restore. See docs/restoring-events.md."
  task :download_archive_files => [:environment] do
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket(Rails.application.config.s3_export.bucket)
    bucket.objects.each do |object|
      File.write("tmp/#{object.key}", object.get.body.read)
    end
  end

  desc "Import a set of local event archives. See docs/restoring-events.md."
  task :import_local_archives => [:environment] do
    paths = Dir.glob("tmp/events/*").reverse
    Parallel.each(paths) do |path|
      puts "\nImporting #{path}"
      Events::S3Importer.new.import_by_path(path)
    end
  end
end
