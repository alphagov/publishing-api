class AddPartSlugToLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :links, :part_slug, :text
  end
end
