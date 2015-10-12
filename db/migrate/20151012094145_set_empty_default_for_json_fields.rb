class SetEmptyDefaultForJsonFields < ActiveRecord::Migration
  def change
    change_column_default(:events, :payload, {})

    change_column_default(:draft_content_items, :access_limited, {})
    change_column_default(:draft_content_items, :details, {})
    change_column_default(:draft_content_items, :metadata, {})
    change_column_default(:draft_content_items, :redirects, [])
    change_column_default(:draft_content_items, :routes, [])

    change_column_default(:live_content_items, :details, {})
    change_column_default(:live_content_items, :metadata, {})
    change_column_default(:live_content_items, :redirects, [])
    change_column_default(:live_content_items, :routes, [])

    change_column_default(:link_sets, :links, {})
  end
end
