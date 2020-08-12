desc "Generate a report of all content with tables."
task table_report: :environment do
  Reports::TableReporter.call
end
