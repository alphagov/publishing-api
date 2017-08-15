class AddForeignKeyToLinkContentItems < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :live_content_items, :draft_content_items
  end
end
