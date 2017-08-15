class RetireLinksColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :link_sets, :links, :legacy_links
  end
end
