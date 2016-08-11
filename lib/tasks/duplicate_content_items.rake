namespace :duplicate_content_items do
  desc "Checks for the presence of dupicate content_items"
  task check: :environment do
    DataHygiene::DuplicateContentItem.new.check
  end
end
