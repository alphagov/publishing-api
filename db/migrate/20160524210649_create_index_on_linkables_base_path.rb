class CreateIndexOnLinkablesBasePath < ActiveRecord::Migration
  def change
    add_index :linkables, :base_path
  end
end
