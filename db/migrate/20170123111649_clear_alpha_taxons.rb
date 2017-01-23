class ClearAlphaTaxons < ActiveRecord::Migration[5.0]
  def up
    Link.where(link_type: "taxons").where("created_at < '2017-01-23'").delete_all
  end
end
