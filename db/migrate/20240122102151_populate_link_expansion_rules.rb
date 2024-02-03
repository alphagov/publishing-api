class PopulateLinkExpansionRules < ActiveRecord::Migration[7.1]
  def up
    ExpansionRules::MULTI_LEVEL_LINK_PATHS.each do |path|
      expansion_rule = ExpansionRule.create!(name: path.inspect)
      parent = nil
      path.each do |elem|
        case elem
        when Array
          step = ExpansionRuleStep.create!(link_type: elem.first.to_s)
          ExpansionRuleStepRelationship.create!(expansion_rule:, child_step_id: step.id, parent_step_id: parent&.id)
          ExpansionRuleStepRelationship.create!(expansion_rule:, child_step_id: step.id, parent_step_id: step.id)
          parent = step
        when Symbol
          step = ExpansionRuleStep.create!(link_type: elem.to_s)
          ExpansionRuleStepRelationship.create!(expansion_rule:, child_step_id: step.id, parent_step_id: parent&.id)
          parent = step
        else
          raise "Unexpected class #{elem.class}"
        end
      end
    end

    ExpansionRules::REVERSE_LINKS.each do |key, value|
      ExpansionReverseRule.create!(name: value, link_type: key)
    end
  end

  def down
    ExpansionRuleStepRelationship.delete_all
    ExpansionRuleStep.delete_all
    ExpansionRule.delete_all
    ExpansionReverseRule.delete_all
  end
end
