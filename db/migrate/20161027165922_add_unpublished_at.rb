class AddUnpublishedAt < ActiveRecord::Migration[5.0]
  def change
    add_column :unpublishings, :unpublished_at, :datetime, null: true
  end
end
