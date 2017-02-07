class ClearAlphaTaxonsAgain < ActiveRecord::Migration[5.0]
  def up
    Link.where(link_type: "taxons").where("created_at < '2017-02-7'").delete_all
  end
end
