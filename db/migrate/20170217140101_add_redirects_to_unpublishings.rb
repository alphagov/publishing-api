class AddRedirectsToUnpublishings < ActiveRecord::Migration[5.0]
  def change
    add_column :unpublishings, :redirects, :json
  end
end
