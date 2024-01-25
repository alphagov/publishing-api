class LinkExpansionRuleRelationship < ApplicationRecord
  belongs_to :link_expansion_rule, class_name: "LinkExpansionRule"
  belongs_to :parent, class_name: "LinkExpansionRule", optional: true
end
