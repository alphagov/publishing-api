module DataHygiene
  class AccessLimitsCleaner
    def self.cleanup(log: STDOUT)
      run(cleanup: true, log: log)
    end

    def self.report(log: STDOUT)
      run(cleanup: false, log: log)
    end

    def self.run(cleanup:, log:)
      dupe_access_limits_by_content_item = AccessLimit
        .joins("INNER JOIN content_items ON content_items.id = access_limits.content_item_id")
        .group("content_items.id").having("COUNT(access_limits.id) > 1").count

      dupe_access_limits_by_content_item.each do |count|
        content_item_id, access_limit_count = count
        dupe_access_limits = AccessLimit.where(content_item_id: content_item_id).limit(access_limit_count - 1).order(updated_at: :asc)
        log.puts "destroying AccessLimits: #{dupe_access_limits.map(&:id)} for content_item_id: #{content_item_id}"
        dupe_access_limits.destroy_all if cleanup
      end

      published_access_limits = AccessLimit
        .joins("INNER JOIN content_items ON content_items.id = access_limits.content_item_id")
        .joins("INNER JOIN states ON states.content_item_id = content_items.id")
        .where("states.name = 'published'")

      log.puts "destroying #{published_access_limits.count} AccessLimits for published content."
      log.puts published_access_limits.map(&:id)
      published_access_limits.destroy_all if cleanup
    end
  end
end
