class AddSpecialistPublisherChangeNotes < ActiveRecord::Migration[5.0]
  def change
    Queries::GetChangeHistory.("specialist-publisher").each do |change_data|
      ChangeNote.find_or_create_by(change_data)
    end
  end
end
