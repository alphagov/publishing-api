require "live_content_report_exporter"

desc "Generates a CSV report of all live documents for the supplied publishing app(s)"
task :live_content_report, [] => :environment do |_, args|
  publishing_apps = args.extras
  if publishing_apps.empty?
    puts %(Usage: rake live_content_report[publishing_app]\n\npublishing_app can be a single publishing_app, or a comma separated list)
    abort
  end

  live_content_report = LiveContentReportExporter.new(publishing_apps)
  puts "Exporting #{live_content_report.total} live documents published by #{publishing_apps.to_sentence} to #{File.absolute_path(live_content_report.file_path)}"
  live_content_report.export(progress: lambda { |index, count|
    if ((index + 1) % 1000).zero? || (index + 1) == count
      puts "processed: #{index + 1}/#{count}"
    end
  })
  puts "Done!"
end
