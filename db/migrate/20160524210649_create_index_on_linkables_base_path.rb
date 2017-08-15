class CreateIndexOnLinkablesBasePath < ActiveRecord::Migration[4.2]
  def change
    add_index :linkables, :base_path
  end
end
