module DataHygiene
  module DuplicateContentItem
    module ResultsHelper
    protected

      def content_items_string_to_hash(field)
        field.scan(/\((.+?)\)/).flatten.map do |id_time|
          id, time = id_time.split(",")
          {
            content_item_id: id.to_i,
            updated_at: Time.zone.parse(time.gsub(/\\"/, "")),
          }
        end
      end

      def content_ids_string_to_array(field)
        field[1...-1].split(",")
      end

      def content_item_ids_from_duplicates(duplicates)
        get_content_item_ids = ->(row) do
          row[:content_items].map { |pair| pair[:content_item_id] }
        end
        duplicates.map(&get_content_item_ids).flatten.uniq
      end

      def content_ids_from_duplicates(duplicates, field = :content_id)
        set = duplicates.inject(Set.new) do |memo, row|
          memo.merge(Array(row[field]))
        end
        set.to_a
      end
    end
  end
end
