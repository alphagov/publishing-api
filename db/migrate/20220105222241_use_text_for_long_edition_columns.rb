class UseTextForLongEditionColumns < ActiveRecord::Migration[6.1]
  def up
    change_table :editions, bulk: true do |t|
      t.change :base_path, :text
      t.change :description, :text
      t.change :title, :text
    end
  end

  def down
    change_table :editions, bulk: true do |t|
      t.change :base_path, :string
      t.change :description, :string
      t.change :title, :string
    end
  end
end
