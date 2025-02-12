class RemoveRenderingAppFromEditions < ActiveRecord::Migration[8.0]
  def change
    remove_column :editions, :rendering_app, :string
  end
end
