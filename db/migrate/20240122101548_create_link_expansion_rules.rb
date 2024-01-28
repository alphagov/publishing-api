class CreateLinkExpansionRules < ActiveRecord::Migration[7.1]
  def change
    create_table :link_expansion_rules do |t|
      t.text :link_type
      t.timestamps
      t.index %w[link_type], name: "index_lers_on_link_type"
    end

    create_table :link_expansion_rule_relationships do |t|
      t.bigint :link_expansion_rule_id
      t.bigint :parent_id
      t.timestamps
      t.index %w[link_expansion_rule_id parent_id], name: "index_lerrs_on_lers_id_and_parent_id"
    end

    create_table :link_expansion_reverse_rules do |t|
      t.text :name
      t.text :link_type
      t.timestamps
      t.index %w[name], name: "index_reverse_lers_on_name"
      t.index %w[link_type], name: "index_reverse_lers_on_link_type"
    end
  end
end
