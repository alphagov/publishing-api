class AddDescriptionStringToEdition < ActiveRecord::Migration[5.0]
  def change
    add_column :editions, :description_string, :string
  end
end
