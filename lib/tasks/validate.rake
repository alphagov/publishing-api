namespace :db do
  desc "Validates every record in the database"
  task validate: :environment do
    DatabaseRecordValidator.validate
  end

  desc "Validates the version sequence for all editions in the database"
  task validate_versions: :environment do
    VersionValidator.validate
  end
end
