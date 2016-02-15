desc "Validates every record in the database"
task validate: :environment do
  Tasks::Validator.validate
end
