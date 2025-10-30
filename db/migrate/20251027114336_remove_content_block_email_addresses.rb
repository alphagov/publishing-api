require_relative "helpers/delete_content"

class RemoveContentBlockEmailAddresses < ActiveRecord::Migration[8.0]
  def change
    document_ids = Edition.where(document_type: "content_block_email_address").pluck(:document_id)
    content_ids = Document.where(id: document_ids).pluck(:content_id)
    Helpers::DeleteContent.destroy_documents_with_links(content_ids)
  end
end
