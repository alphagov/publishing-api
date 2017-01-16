class SetDocumentIdOnContentItems < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    Document.find_each do |doc|
      ContentItem.where(content_id: doc.content_id, locale: doc.locale)
        .update_all(document_id: doc.id)
    end
  end
end
