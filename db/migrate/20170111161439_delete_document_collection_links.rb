class DeleteDocumentCollectionLinks < ActiveRecord::Migration[5.0]
  def change
    Link.delete_all(link_type: "document_collections")
  end
end
