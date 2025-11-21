class AddIndexesForFetchingContentBlocks < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :editions, %i[document_id id], algorithm: :concurrently
    add_index :links, %i[link_type edition_id], include: %i[target_content_id created_at], algorithm: :concurrently
  end
end
