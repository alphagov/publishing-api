class AddDocumentTypeAndSchemaNameToContentItems < ActiveRecord::Migration[4.2]
  def change
    add_column :content_items, :document_type, :string
    add_column :content_items, :schema_name, :string
  end
end
