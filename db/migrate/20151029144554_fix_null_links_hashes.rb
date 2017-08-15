class FixNullLinksHashes < ActiveRecord::Migration[4.2]
  def change
    change_column_null :link_sets, :links, false, {}
  end
end
