module Tasks
  class VersionResolver
    def self.resolve
      VersionValidator.validate.each do |content_id, invalid_version_id, versions, version_ids|
        index = version_ids.index(invalid_version_id)
        # Get the subset of versions needing update ie [2, 2, 3] from [1, 2, 2, 3]
        version_ids[index..-1].each do |version_id|
          # Only update this version if it's the same number as the last
          if versions[index] == versions[index - 1]
            invalid_version = UserFacingVersion.find(version_id)
            invalid_version.number += 1
            invalid_version.save(validate: false)

            if version_id == version_ids.last
              updated_version_numbers = UserFacingVersion.where(id: version_ids).map(&:number).sort
              puts "Resolved versions for #{content_id} from #{versions} to #{updated_version_numbers}"
            end
          end
        end
      end
    end
  end
end
