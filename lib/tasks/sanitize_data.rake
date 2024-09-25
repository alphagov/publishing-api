desc "Sanitize access limited data"
task sanitize_data: :environment do
  DataSanitizer.delete_access_limited($stdout)
end

namespace :db do
  desc "Resolves invalid versions detected by validate:versions task"
  task resolve_invalid_versions: :environment do
    VersionResolver.resolve
  end
end
