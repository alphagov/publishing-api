namespace :db do
  desc "Validates every record in the database"
  task validate: :environment do
    Tasks::DatabaseRecordValidator.validate
  end
end
