namespace :db do
  desc "Validates every record in the database"
  task validate: :environment do
    Tasks::DatabaseRecordValidator.validate
  end

  desc "Validates the version sequence for all content items in the database"
  task validate_versions: :environment do
    Tasks::VersionValidator.validate
  end
end
