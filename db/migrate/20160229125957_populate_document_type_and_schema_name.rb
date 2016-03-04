class PopulateDocumentTypeAndSchemaName < ActiveRecord::Migration
  def change
    puts "Populating document_type for specialist documents"
    ContentItem.where(format: ['specialist_document', 'placeholder_specialist_document']).update_all("document_type = (details #>> '{metadata,document_type}')")
    puts "Populating document_type for other documents"
    ContentItem.where(document_type: nil).update_all('document_type = format')
    puts "Populating schema_name for all documents"
    ContentItem.where(schema_name: nil).update_all('schema_name = format')
  end
end
