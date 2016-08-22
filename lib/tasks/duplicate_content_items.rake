namespace :duplicate_content_items do
  desc "Perform all checks for duplicate content items"
  task all: [:version_for_locale, :state_for_locale, :base_path_for_state]

  desc "Check content items for any version for locale conflicts"
  task version_for_locale: :environment do
    checker = DataHygiene::DuplicateContentItem::VersionForLocale.new
    puts conflict_message(
      checker.number_of_duplicates, "version for locale"
    )
    checker.log if checker.has_duplicates?
  end

  desc "Check content items for any state for locale conflicts"
  task state_for_locale: :environment do
    checker = DataHygiene::DuplicateContentItem::StateForLocale.new
    puts conflict_message(
      checker.number_of_duplicates, "state for locale"
    )
    checker.log if checker.has_duplicates?
  end

  desc "Check content items for any base path for state conflicts"
  task base_path_for_state: :environment do
    checker = DataHygiene::DuplicateContentItem::BasePathForState.new
    puts conflict_message(
      checker.number_of_duplicates, "base path for state"
    )
    checker.log if checker.has_duplicates?
  end

  def conflict_message(number, name)
    plural = number != 1
    emoji = case number
            when 0 then "😀"
            when 1...50 then "😞"
            when 50...1_000 then "😭"
            when 1_000...Float::INFINITY then "😱"
            else "😕"
            end
    "There #{plural ? 'are' : 'is'} #{number} #{name} conflict#{plural ? 's' : ''} #{emoji}"
  end
end
