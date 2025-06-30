module Queries
  module RecursiveLinkExpansion
    class LinkExpansionRules
      RULES_BY_SCHEMA_NAME = {
        ministers_index: [
          { "type": "ordered_cabinet_ministers", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_also_attends_cabinet", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_ministerial_departments", "reverse": false, "links": [{ "type": "ordered_ministers", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [{ "type": "ordered_roles", "reverse": true, "links": [] }] }] }] }] },
          { "type": "ordered_assistant_whips", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_baronesses_and_lords_in_waiting_whips", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_house_lords_whips", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_house_of_commons_whips", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
          { "type": "ordered_junior_lords_of_the_treasury_whips", "reverse": false, "links": [{ "type": "person", "reverse": true, "links": [{ "type": "role", "reverse": false, "links": [] }] }] },
        ],
      }.with_indifferent_access.freeze

      def self.for(schema_name)
        RULES_BY_SCHEMA_NAME.fetch(schema_name)
      end
    end
  end
end
