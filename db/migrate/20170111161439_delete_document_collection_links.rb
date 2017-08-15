class DeleteDocumentCollectionLinks < ActiveRecord::Migration[5.0]
  def change
    Link.where(link_type: "document_collections").delete_all
  end
end
