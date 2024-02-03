class CreateLinkExpansionRules < ActiveRecord::Migration[7.1]
  def change
    create_table :expansion_rules do |t|
      t.text :name
      t.timestamps
    end

    create_table :expansion_rule_steps do |t|
      t.text :link_type
      t.timestamps
    end

    create_table :expansion_rule_step_relationships do |t|
      t.belongs_to :expansion_rule, foreign_key: true
      t.references :parent_step, foreign_key: { to_table: :expansion_rule_steps }
      t.references :child_step, foreign_key: { to_table: :expansion_rule_steps }
      t.timestamps
    end

    create_table :expansion_reverse_rules do |t|
      t.text :name
      t.text :link_type
      t.timestamps
      t.index %w[name], name: "index_reverse_lers_on_name"
      t.index %w[link_type], name: "index_reverse_lers_on_link_type"
    end
  end
end
