class AddContentItemFkToLinks < ActiveRecord::Migration[5.0]
  def change
    add_reference :links, :edition, index: true, foreign_key: { on_delete: :cascade }
  end
end
