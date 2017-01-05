class AddLockVersionToLinkSet < ActiveRecord::Migration[5.0]
  def change
    add_column :link_sets, :lock_version, :integer
    reversible do |dir|
      dir.up do
        change_column :link_sets, :lock_version, :integer, default: 1
      end
    end
  end
end
