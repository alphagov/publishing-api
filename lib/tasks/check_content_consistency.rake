namespace :check_content_consistency do
def check_content(checker, ignore_recent)
  errors = checker.call(content_id, locale)

  if errors.any?
    puts "#{content_id} #{locale} 😱"
    puts errors
  end

  errors.none?
end

desc "Check all the documents for consistency with the router-api and content-store"
task :check_content_consistency, [:ignore_recent] => [:environment] do |_, args|
  checker = ContentConsistencyChecker.new(args.fetch(:ignore_recent, false) == "true")
  documents = Document.pluck(:content_id, :locale)
  failures = documents.reject do |content_id, locale|
    check_content(checker, content_id, locale)
  end
  puts "Results: #{failures.count} failures out of #{documents.count}."
end
