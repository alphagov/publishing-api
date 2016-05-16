class RemoveColumnLegacyLinksFromLinkSet < ActiveRecord::Migration
  def change
    remove_column :link_sets, :legacy_links, :json
  end
end
