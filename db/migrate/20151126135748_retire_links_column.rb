class RetireLinksColumn < ActiveRecord::Migration
  def change
    rename_column :link_sets, :links, :legacy_links
  end
end
