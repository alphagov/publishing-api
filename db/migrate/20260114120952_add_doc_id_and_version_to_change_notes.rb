class AddDocIdAndVersionToChangeNotes < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      change_table :change_notes, bulk: true do |t|
        t.integer :document_id, :user_facing_version
      end
    end
  end
end
