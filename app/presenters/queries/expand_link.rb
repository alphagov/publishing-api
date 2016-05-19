module Presenters
  module Queries
    class ExpandLink
      attr_reader :item, :type

      def initialize(item, type, rules)
        @item = item
        @type = type
        @rules = rules
      end

      def expand_link
        rules.expansion_fields(type).each_with_object({}) do |field, subhash|
          subhash[field] = item.public_send(field)
        end
      end

    private

      attr_reader :rules
    end
  end
end
