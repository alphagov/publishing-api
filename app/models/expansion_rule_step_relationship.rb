class ExpansionRuleStepRelationship < ApplicationRecord
  belongs_to :expansion_rule
  has_many :expansion_rule_steps, dependent: :destroy
  belongs_to :parent_step, class_name: "ExpansionRuleStep", optional: true
  belongs_to :child_step, class_name: "ExpansionRuleStep"
end
