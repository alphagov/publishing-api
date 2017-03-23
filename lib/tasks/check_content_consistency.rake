require "content_consistency_checker"

def report_errors(errors, content_store)
  Airbrake.notify(
    "Inconsistent #{content_store} documents",
    parameters: {
      errors: errors,
    }
  )

  errors.each do |base_path, item_errors|
    puts "#{base_path} 😱"
    puts item_errors
  end
end

desc "Check all the documents for consistency with the router-api and content-store"
task :check_content_consistency, [:content_store, :content_dump] => [:environment] do |_, args|
  raise "Missing content store." unless args[:content_store]
  raise "Missing content dump." unless args[:content_dump]
  raise "Invalid content store." unless ["live", "draft"].include?(args[:content_store])

  checker = ContentConsistencyChecker.new(args[:content_store], args[:content_dump])
  checker.check_editions
  checker.check_content

  errors = checker.errors
  report_errors(errors, args[:content_store]) if errors.any?
end
