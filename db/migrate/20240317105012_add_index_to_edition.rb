class AddIndexToEdition < ActiveRecord::Migration[7.1]
  def change
    add_index :editions,
              %i[state document_type id],
              order: { state: :asc, document_type: :asc, id: :desc },
              where: "state <> 'superseded'",
              unique: true
  end
end
