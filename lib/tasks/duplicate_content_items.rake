namespace :duplicate_content_items do
  desc "Perform all checks for duplicate content items"
  task all: %i[version_for_locale state_for_locale base_path_for_state]

  desc "Check content items for any version for locale conflicts"
  task version_for_locale: :environment do
  end

  desc "Check content items for any state for locale conflicts"
  task state_for_locale: :environment do
  end

  desc "Check content items for any base path for state conflicts"
  task base_path_for_state: :environment do
  end
end
