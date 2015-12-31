desc "Sanitize access limited data"
task sanitize_data: :environment do
  Tasks::DataSanitizer.delete_access_limited(STDOUT)
end
