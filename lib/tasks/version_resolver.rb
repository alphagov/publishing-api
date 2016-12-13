module Tasks
  class VersionResolver
    def self.resolve
      VersionValidator.validate.each do |content_id, invalid_content_item_id, versions, content_item_ids|
        index = content_item_ids.index(invalid_content_item_id)
        # Get the subset of versions needing update ie [2, 2, 3] from [1, 2, 2, 3]
        content_item_ids[index..-1].each do |content_item_id|
          # Only update this version if it's the same number as the last
          if versions[index] == versions[index - 1]
            invalid_version = ContentItem.find(content_item_id)
            invalid_version.user_facing_version += 1
            invalid_version.save(validate: false)

            if content_item_id == content_item_ids.last
              updated_version_numbers = ContentItem.where(id: content_item_ids).map(&:user_facing_version).sort
              puts "Resolved versions for #{content_id} from #{versions} to #{updated_version_numbers}"
            end
          end
        end
      end
    end
  end
end
