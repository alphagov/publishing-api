class LinkExpansionRule < ApplicationRecord
  has_many :relationships, class_name: "LinkExpansionRuleRelationship", dependent: :destroy
  has_many :parents, through: :relationships, source: :parent

  has_many :reverse_relationships, foreign_key: "parent_id", class_name: "LinkExpansionRuleRelationship", dependent: :destroy
  has_many :children, through: :reverse_relationships, source: :link_expansion_rule
end
