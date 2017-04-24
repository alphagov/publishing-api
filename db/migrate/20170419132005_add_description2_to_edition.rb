class AddDescription2ToEdition < ActiveRecord::Migration[5.0]
  def change
    add_column :editions, :description2, :string
  end
end
