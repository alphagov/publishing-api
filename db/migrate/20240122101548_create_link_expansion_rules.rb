class CreateLinkExpansionRules < ActiveRecord::Migration[7.1]
  def change
    create_table :link_expansion_rules do |t|
      t.text :link_type
      t.timestamps
    end

    create_table :link_expansion_rule_relationships do |t|
      t.bigint :link_expansion_rule_id
      t.bigint :parent_id
      t.timestamps
    end

    create_table :link_expansion_reverse_rules do |t|
      t.text :name
      t.text :link_type
      t.timestamps
    end
  end
end
