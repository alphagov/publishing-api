class RemoveLinkSetIdForeignKey < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :links, to_table: :link_sets, column: :link_set_id
  end
end
