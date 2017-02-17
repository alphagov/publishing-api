class AddForeignKeyForUnpublishings < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :unpublishings, :editions
  end
end
