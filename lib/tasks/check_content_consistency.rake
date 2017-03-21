namespace :check_content_consistency do
  def check_content(content_id, locale, ignore_recent)
    checker = ContentConsistencyChecker.new(content_id, locale, ignore_recent)
    errors = checker.call

    if errors.any?
      Airbrake.notify(
        "Found an inconsistent document: #{content_id} #{locale} 😱",
        parameters: {
          content_id: content_id,
          locale: locale,
          errors: errors,
        }
      )
    end

    errors.none?
  end

  desc "Check documents for consistency with the router-api and content-store"
  task :one, [:content_id, :locale] => [:environment] do |_, args|
    content_id = args[:content_id]
    locale = args[:locale] || "en"
    check_content(content_id, locale, false)
  end

  desc "Check all the documents for consistency with the router-api and content-store"
  task :all, [:ignore_recent] => [:environment] do |_, args|
    documents = Document.pluck(:content_id, :locale)
    failures = documents.reject do |content_id, locale|
      check_content(
        content_id, locale,
        args.fetch(:ignore_recent, false) == "true"
      )
    end
    puts "Results: #{failures.count} failures out of #{documents.count}."
  end
end
