class RemoveMinistersLinks < ActiveRecord::Migration[6.0]
  def up
    Link.where(link_type: "ministers").destroy_all
  end
end
