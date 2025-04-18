class AddGraphqlOptimisationIndexToEditions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :editions, %i[document_id document_type], where: "(details ->> 'current') = 'true'", name: :index_editions_on_document_id_and_document_type_current, algorithm: :concurrently
    add_index :editions, %i[document_id document_type], where: "content_store = 'live'", name: :index_editions_on_document_id_and_document_type_live, algorithm: :concurrently
    add_index :links, %i[link_set_id link_type], algorithm: :concurrently
  end
end
