class DeleteOrphanedLinks < ActiveRecord::Migration[5.1]
  def up
    Link.where(edition_id: nil, link_set_id: nil).delete_all
  end
end
