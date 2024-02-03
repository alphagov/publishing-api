class ExpansionRule < ApplicationRecord
  has_many :expansion_rule_step_relationships, dependent: :destroy
end
