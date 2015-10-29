class FixNullLinksHashes < ActiveRecord::Migration
  def change
    change_column_null :link_sets, :links, false, {}
  end
end
