require "data_hygiene/content_consistency_checker"

def report_errors(errors, content_store)
  GovukError.notify(
    "Documents inconsistent with the #{content_store} content store",
    level: "warning",
    extra: { errors: errors },
  )

  errors.each do |base_path, item_errors|
    puts "#{base_path} 😱"
    puts item_errors
  end
end

desc "Check all the documents for consistency with the content-store"
task :check_content_consistency, %i[content_store content_dump] => [:environment] do |_, args|
  raise "Missing content store." unless args[:content_store]
  raise "Invalid content store." unless %w(live draft).include?(args[:content_store])
  raise "Missing content dump." unless args[:content_dump]

  content_dump = ContentDumpLoader.load(args[:content_dump])

  checker = DataHygiene::ContentConsistencyChecker.new(args[:content_store], content_dump)
  checker.check_editions
  checker.check_content

  errors = checker.errors
  report_errors(errors, args[:content_store]) if errors.any?
end
