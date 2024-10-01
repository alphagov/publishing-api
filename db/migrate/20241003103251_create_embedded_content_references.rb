class CreateEmbeddedContentReferences < ActiveRecord::Migration[7.2]
  def change
    create_table :embedded_content_references do |t|
      t.string :friendly_id, null: false, index: true
      t.uuid :content_id, null: false, index: true

      t.timestamps
    end
  end
end
