module Tasks
  module VersionValidator
    class << self
      def validate
        results = nil

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

          items = versions.zip(states, base_paths)
          items.sort_by!(&:first)

          valid_version_sequence = true

          items.each.with_index do |item, index|
            item_version = item.first

            if item_version != index + 1
              valid_version_sequence = false
            end
          end

          unless valid_version_sequence
            puts "Invalid version sequence for #{content_id}, #{locale}:"
            items.each { |i| puts i.inspect }
            puts
          end
        end
      end

      def query
        <<-SQL
          select
            ci.content_id,
            t.locale,

            -- select arrays of supporting attributes
            array_agg(s.name) as states,
            array_agg(v.number) as versions,
            array_agg(l.base_path) as base_paths

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
    end
  end
end
