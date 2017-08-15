class RemoveColumnLegacyLinksFromLinkSet < ActiveRecord::Migration[4.2]
  def change
    remove_column :link_sets, :legacy_links, :json
  end
end
