# Read and write the schemas
module SchemaGenerator
  module SortedHash
    refine Hash do
      def deep_sort(&block)
        recursive_deep_sort(self, &block)
      end

    private

      def recursive_deep_sort(property, parent_key = nil, &block)
        if property.is_a?(Hash)
          children_sorted = property.each_with_object({}) do |(k, v), memo|
            memo[k] = recursive_deep_sort(v, k, &block)
          end

          sorted = children_sorted.sort do |a, b|
            block.call(a, b, parent_key)
          end

          Hash[sorted]
        elsif property.respond_to?(:map)
          property.map { |item| recursive_deep_sort(item, nil, &block) }
        else
          property
        end
      end
    end
  end

  class Schema
    using SchemaGenerator::SortedHash

    def self.read(filename)
      @parsed_json_cache ||= {}
      @parsed_json_cache[filename] ||= JSON.parse(File.read(filename))
    end

    def self.write(full_filename, schema_hash)
      schema_json = "#{JSON.pretty_generate(ordered_schema(schema_hash))}\n"
      FileUtils.mkdir_p(File.dirname(full_filename))
      File.write(full_filename, schema_json)
    end

    def self.ordered_schema(schema_hash)
      # Custom consistent sorting for JSON Schema objects
      schema_hash.deep_sort do |(a, _), (b, _), parent_key|
        a = a.to_s
        b = b.to_s
        # We don't want to sort any items properties
        next a <=> b if parent_key == "properties"
        # a description is always first
        next (a == "description" ? -1 : 1) if [a, b].include?("description")
        # then we want anything prefixed with a $
        next a <=> b if [a, b].grep(/^\$/).any?
        # Then we want type and required
        next (a == "type" ? -1 : 1) if [a, b].include?("type")
        next (a == "required" ? -1 : 1) if [a, b].include?("required")
        # definitions are the last item
        next (a == "definitions" ? 1 : -1) if [a, b].include?("definitions")

        # otherwise it's alphabetical
        a <=> b
      end
    end
  end
end
