module DataHygiene
  class DuplicateContentItem
    def check
      log if duplicates.any?
    end

  private

    def log
      Airbrake.notify_or_ignore(
        DuplicateContentItemError.new("Duplicate content items"),
        parameters: parameters
      )
    end

    def duplicates
      @results ||= ActiveRecord::Base.connection.execute(sql)
    end

    def parameters
      { duplicates: duplicates.map(&:to_json) }
    end

    def sql
      <<-SQL
        SELECT array_agg(content_items.id),
        states.name, translations.locale, user_facing_versions.number,
        locations.base_path
        FROM content_items
        INNER JOIN states
        ON content_items.id = states.content_item_id
        INNER JOIN translations
        ON content_items.id = translations.content_item_id
        INNER JOIN locations
        ON content_items.id = locations.content_item_id
        INNER JOIN user_facing_versions
        ON content_items.id = user_facing_versions.content_item_id
        WHERE states.name NOT IN ('superseded', 'unpublished')
        GROUP BY states.name, translations.locale,
        user_facing_versions.number, locations.base_path
        HAVING COUNT(content_items.id) > 1;
      SQL
    end

    class DuplicateContentItemError < StandardError; end;
    class DuplicateVersionForLocaleError < StandardError; end;
    class DuplicateStateForLocaleError < StandardError; end;
  end
end
