module Tasks
  module VersionValidator
    class << self
      def validate
        results = nil
        invalid_items = []

        puts "Running query..."
        time_taken = Benchmark.realtime do
          results = ActiveRecord::Base.connection.execute(query)
        end
        puts "Done. Took #{time_taken.round(1)} seconds."
        puts

        results.each do |r|
          content_id = r.fetch("content_id")
          locale = r.fetch("locale")
          versions = parse(r.fetch("versions")).map(&:to_i)
          states = parse(r.fetch("states"))
          base_paths = parse(r.fetch("base_paths"))
          version_ids = parse(r.fetch("version_ids")).map(&:to_i)

          items = versions.zip(states, base_paths, version_ids)
          items.sort! { |a, b| workflow_sort(a, b) }

          valid_version_sequence = true

          items.each.with_index do |item, index|
            item_version = item.first

            if item_version != index + 1
              valid_version_sequence = false
              invalid_items << [content_id, item.last, items.map(&:first), items.map(&:last)]
            end
          end

          unless valid_version_sequence
            puts "Invalid version sequence for #{content_id}, #{locale}:"
            items.each { |i| puts i.inspect }
            puts
          end
        end

        invalid_items
      end

      def query
        <<-SQL
          select
            ci.content_id,
            t.locale,

            -- select arrays of supporting attributes
            array_agg(s.name) as states,
            array_agg(v.number) as versions,
            array_agg(l.base_path) as base_paths,
            array_agg(v.id) as version_ids

          from content_items ci

          -- join supporting objects
          join states s on s.content_item_id = ci.id
          join user_facing_versions v on v.content_item_id = ci.id
          join translations t on t.content_item_id = ci.id
          join locations l on l.content_item_id = ci.id

          group by ci.content_id, t.locale
        SQL
      end

      def parse(array_string)
        array_string[1..-2].split(",")
      end

      def workflow_sort(a, b)
        return -1 if a.second == "superseded" && b.second == "published"
        return 1 if a.second == "published" && b.second == "superseded"
        return -1 if a.second == "superseded" && b.second == "draft"
        return 1 if a.second == "draft" && b.second == "superseded"
        return -1 if a.second == "published" && b.second == "draft"
        return 1 if a.second == "draft" && b.second == "published"
        a.first <=> b.first
      end
    end
  end
end
