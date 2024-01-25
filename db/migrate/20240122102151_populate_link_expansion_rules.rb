class PopulateLinkExpansionRules < ActiveRecord::Migration[7.1]
  def up
    ExpansionRules::MULTI_LEVEL_LINK_PATHS.each do |path|
      parent = nil
      path.each do |elem|
        case elem
        when Array
          ler = LinkExpansionRule.create!(link_type: elem.first.to_s, parents: [parent].compact)
          if parent.nil?
            LinkExpansionRuleRelationship.create!(link_expansion_rule_id: ler.id, parent_id: nil)
          end
          ler.parents << ler
          ler.save!
          parent = ler
        when Symbol
          ler = LinkExpansionRule.create!(link_type: elem.to_s, parents: [parent].compact)
          if parent.nil?
            LinkExpansionRuleRelationship.create!(link_expansion_rule_id: ler.id, parent_id: nil)
          end
          parent = ler
        else
          raise "Unexpected class #{elem.class}"
        end
      end
    end

    ExpansionRules::REVERSE_LINKS.each do |key, value|
      LinkExpansionReverseRule.create!(name: value, link_type: key)
    end
  end

  def down
    LinkExpansionRule.delete_all
    LinkExpansionRuleRelationship.delete_all
    LinkExpansionReverseRule.delete_all
  end
end
