class SetDefaultVersionToZero < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:draft_content_items, :version, 0)
    change_column_default(:live_content_items, :version, 0)
    change_column_default(:link_sets, :version, 0)
  end
end
