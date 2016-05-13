class UpdateFormatToDualSpecialistPublisher < ActiveRecord::Migration
  def change
    ContentItem.where(document_type: ['specialist_document', 'placeholder_specialist_document'])
      .update_all("document_type = (details #>> '{metadata,document_type}')")
  end
end
