class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.uuid :content_id, null: false
      t.string :locale, null: false
    end

    add_index :documents, [:content_id, :locale], :unique => true
  end
end
