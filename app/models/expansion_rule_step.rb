class ExpansionRuleStep < ApplicationRecord
  has_many :parent_relationships, class_name: "ExpansionRuleStepRelationship", foreign_key: "child_step_id", dependent: :destroy
  has_many :parents, through: :parent_relationships, source: :parent_step

  has_many :child_relationships, class_name: "ExpansionRuleStepRelationship", foreign_key: "parent_step_id", dependent: :destroy
  has_many :children, through: :child_relationships, source: :child_step
end
