class AddUniquenessConstraintToUnpublishingEditions < ActiveRecord::Migration[5.2]
  def change
    remove_index :unpublishings, :edition_id if index_exists?(:unpublishings, :edition_id)
    add_index :unpublishings, :edition_id, unique: true
  end
end
