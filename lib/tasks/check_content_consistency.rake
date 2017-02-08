namespace :check_content_consistency do
  def check_content(content_id, locale)
    checker = ContentConsistencyChecker.new(content_id, locale)
    errors = checker.call

    if errors.any?
      puts "#{content_id} 😱"
      puts errors
    end

    errors.none?
  end

  desc "Check documents for consistency with the router-api and content-store"
  task :one, [:content_id, :locale] => [:environment] do |_, args|
    content_id = args[:content_id]
    locale = args[:locale] || "en"
    check_content(content_id, locale)
  end

  desc "Check all the documents for consistency with the router-api and content-store"
  task all: :environment do
    documents = Document.pluck(:content_id, :locale)
    failures = documents.reject do |content_id, locale|
      check_content(content_id, locale)
    end
    puts "Results: #{failures.count} failures out of #{documents.count}."
  end
end
