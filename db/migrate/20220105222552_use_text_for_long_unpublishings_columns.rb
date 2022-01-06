class UseTextForLongUnpublishingsColumns < ActiveRecord::Migration[6.1]
  def up
    change_table :unpublishings, bulk: true do |t|
      t.change :alternative_path, :text
      t.change :explanation, :text
    end
  end

  def down
    change_table :unpublishings, bulk: true do |t|
      t.change :alternative_path, :string
      t.change :explanation, :string
    end
  end
end
