class SetEmptyLinksToHash < ActiveRecord::Migration
  def change
    if LinkSet.column_names.include?("link_set_id")
      LinkSet.where(links: nil).update_all(links: {})
      raise "There are LinkSet records with links=nil, this should not happen!" if LinkSet.where(links: nil).any?
    end
  end
end
